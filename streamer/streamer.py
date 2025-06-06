#import time
from importlib.util import find_spec
import os
import sys
import subprocess as sp
import threading
import socket
import json
import shlex
from io import BytesIO
from base64 import b64decode

import numpy as np
import cv2

from PIL import Image
# Set these optional classes with dummy values so that we can quickly check if they
# were imported.
CamGear = None
OpenAI = None
# We check BadRequestError in a task so we need a dummy version of it in case openai
# is not installed.
class BadRequestError(Exception): pass
# openai needs to be imported here as there is an issue when importing it in a task.
if find_spec('openai'):
	from openai import OpenAI as OpenAIClass
	from openai import BadRequestError as BadRequestErrorClass
	OpenAI, BadRequestError = OpenAIClass, BadRequestErrorClass

from video_wall import VideoWall
from cmd_parsers import main_parser, cmd_stream_parser



def gen_img(prompt):
	"""Request the AI to generate an image based on a prompt and return it."""
	
	global ai_client
	
	if ai_client:
		# By default the response will contain a URL rather than the image bytes.

		imgs_resp = ai_client.images.generate(
			n=1,
			# We use the standard square resolution UE1 uses for the textures.
			size="256x256",
			prompt=prompt,
			response_format='b64_json'
		)
		img_data = b64decode(imgs_resp.data[0].b64_json)
		img = np.array(Image.open(BytesIO(img_data)))
		
		return img
	
	
def handle_cmd(cmd, args=[]):
	"""Process a command.
	
	Some commands start async tasks, the command 'stop' tells them to stop asap."""
	
	global CamGear
	global ai_client
	global BadRequestError
	global stop

	
	if cmd == 'stop':
		# Flag the tasks to stop asap.
		print('Stopping...')
		stop = True
		
	else:
		if cmd.startswith('stream'):
			# Stream a sequence of frames to remote displays.
			# Obtain the frames source and start streaming based on the received
			# arguments.
			
			try:
				args = cmd_stream_parser.parse_args(args)
				
				# Obtain the frames source.

				frame_src = None

				if args.img_path:
					# Get a still image.
					frame_src = cv2.imread(args.img_path)

				
				elif args.vid_path:
					# Get a video.
					if not args.vid_path.startswith('http'):
						# A local path was received so load the video from it.
						frame_src = cv2.VideoCapture(args.vid_path)
						#fps = vid.get(cv2.CAP_PROP_FPS)
					else:
						# A URL was received so load the video from it.
						# (Assuming it's a YouTube URL).
						# Install the needed library if not installed yet.
						if not (find_spec('vidgear') and find_spec('yt_dlp')):
							print('In order to stream a video from YouTube you need both the modules "vidgear" and "yt_dlp" and they were not found. Installing them...')
							sp.check_call([
								sys.executable,
								'-m',
								'pip',
								'install',
								'vidgear',
								'yt_dlp'
							])
							
						if not CamGear:
							vidgear = __import__('vidgear.gears', fromlist=[''])
							CamGear = getattr(vidgear, 'CamGear')
							
						frame_src = CamGear(
							source=args.vid_path,
							stream_mode=True,
							logging=True
						).start()
						
						
				elif args.ai_prompt:
					# Get an AI generated still image.
					if not find_spec('openai'):
						print('In order to generate an image with the AI you need the module "openai" and it was not found.')
						print('the module needs to be installed manually.')
					else:							
						if ai_client:
							print('Generating image...')
							frame_src = gen_img(args.ai_prompt)
						else:
							print('In order to generate an image using the "openai" module you need to set the "OPENAI_API_KEY" environment variable.')
					
					
				elif args.use_camera:
					# Get the camera feed.
					frame_src = cv2.VideoCapture(0, cv2.CAP_DSHOW)
							

				# frame_src may be a numpy array and they can't be converted to bool
				# directly.
				if frame_src is not None:
					# Stream the frames.
					print('Streaming in background...')
					# Start streaming the frames.
					sender_thread = threading.Thread(
						target=sender_task,
						args=(
							args.group,
							frame_src,
							args.glyph_count,
							args.use_alpha,
							args.font_tex_path,
							# Clear the screen if we are streaming a video.
							args.vid_path
						)
					)
					sender_thread.start()
			
			
			except BadRequestError as e:
				# OpenAI error.
				#traceback.print_exc()
				print(e.body['message'])
		
			except SystemExit:
				# argparser attempted to exit the program cause the help was
				# printed.
				pass
				

def get_frames(src):
	"""A generator that yields the next frame if any."""
	
	global CamGear
	
	success = True

	if isinstance(src, np.ndarray):
		# The source is a single image, yield it and stop.
		yield src
		
	elif isinstance(src, cv2.VideoCapture):
		# Yield either video frames or the webcam feed frames.
		while success:
			success, frame = src.read()
			if success:
				yield frame
				
	elif CamGear and isinstance(src, CamGear):
		# Yield a YouTube video frames.
		while success:
			frame = src.read()
			success = frame is not None
			if success:
				yield frame
				
				
def listen_task(host, port):
	"""Listen for data and commands coming from remote display managers."""
	
	global stop
	global video_walls
	global main_args

	
	sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	sock.bind((host, port))
	# Check for new data each second.
	sock.settimeout(1)
	
	print(f'Listening for clients on {host}:{port}\n')
	
	while not stop:
		try:
			data, addr = sock.recvfrom(1024)
			data = json.loads(data)
			
			if main_args.verbose:
				print(f'From: {addr}\tData: {data}')
			
			if data['role'] == 'SERVER':
				# Data or command coming from the server.
				if data['type'] == 'INIT':
					# Initialize the video walls list.
					
					# Delete old walls.
					video_walls = []
					
					# Create the video wall instances.
					for wall_data in data['walls']:
						wall = VideoWall(
							tuple(wall_data['shape']),
							tuple(wall_data['display_res']),
							name = wall_data['group']
						)
						video_walls.append(wall)
						
				elif data['type'] == 'CMD':
					# We received a command with arguments, forward it as if it
					# was received from stdin.
					handle_cmd(data['cmd'], shlex.split(data['args']))
					
					
			elif data['role'] == 'CLIENT':
				# Data coming from the client.
				if data['type'] == 'INIT':
					# Initialize a display and add it to video wall's matrix based
					# on the received group name.
					for wall in video_walls:
						if wall.name == data['group']:
							wall.add_display(sock, addr, tuple(data['position']), send_last_frame=True)
							break
							
				elif data['type'] == 'HEARTBEAT':
					# Update the heartbeat timestamp to keep the remote display alive.
					for wall in video_walls:
						for disp_list in wall.matrix.flatten():
							for disp in disp_list:
								if disp.addr == addr:
									disp.heartbeat()
				
			
		except TimeoutError:
			# Keep listening.
			pass
			
		except ConnectionResetError as e:
			# This error is created by Windows when calling sendto() but stored
			# until recvfrom() gets called.
			pass
			
	# Stop command received, end the task.
			

def sender_task(group, frame_src, glyph_count, use_alpha, font_tex_path, clear=False):
	"""A task to broadcast either a single frame or a sequence of frames."""
	
	global stop
	global video_walls
	
	font_tex = Image.open(font_tex_path)
	# Extract the palette from the font texture.
	raw_font_pal = font_tex.getpalette()
	# Shape it as an array of RGB pixels.
	font_pal_rgb = np.array(raw_font_pal).reshape(-1, 3)
	# Convert each pixel from RGB to BGR as cv2 uses BGR by default.
	font_pal_bgr = font_pal_rgb[:, ::-1]
	# Leave only the pixels that are present in the font texture.
	font_pal_bgr = font_pal_bgr[(not use_alpha):glyph_count]
	
	
	for frame in get_frames(frame_src):
		if stop:
			# Stop command received, stop this task.
			break
		
		for wall in video_walls:
			if wall.name == group:
				# Reshape the image to fit the wall full resolution.
				# We use cv2 to resize cause numpy would require additional steps.
				frame = cv2.resize(
					frame,
					(wall.full_res[1], wall.full_res[0]),
					interpolation=cv2.INTER_LINEAR
				)
				wall.set_frame(frame, font_pal_bgr, use_alpha=use_alpha)
				wall.broadcast_last_frame()
				
				break
		
		# It may be useful to sync with the fps.
		#time.sleep(fps / 1000)

	if clear:
		# Clear the screen by sending a blank frame.
		frame = np.zeros(frame.shape)
		wall.set_frame(frame, font_pal_bgr, use_alpha=use_alpha)
		wall.broadcast_last_frame()
			

def control_task():
	"""A task to listen for input on stdin, parses the input data as command
	and arguments and processes it."""
	
	global stop

	
	try:
		while not stop:
			# NOTE: input() may prevent this thread from stopping.
			split_inp = input('> ').split(' ', 1)
			cmd = split_inp[0]
			args = shlex.split(split_inp[1]) if (len(split_inp) > 1) else []
			handle_cmd(cmd, args)
		
	except EOFError:
		# This error gets thrown when interrupting through the keyboard because of
		# threading.
		print('Stopping...')
		stop = True



if __name__ == '__main__':
	# Set to True to notify all the tasks to stop asap.
	stop = False

	main_args = main_parser.parse_args(sys.argv[1:])

	openai_api_key = os.environ.get('OPENAI_API_KEY')
	ai_client = None
	if openai_api_key:
		ai_client = OpenAI(api_key=openai_api_key)
		# Force submodule load so we don't risk it be loaded in an async task, as
		# it would cause issues with the synchronicity.
		_ = ai_client.images

	video_walls = []

	print()

	# Start the task to listen for data and commands sent by clients.
	listen_thread = threading.Thread(
		target=listen_task,
		args=(main_args.host, main_args.port)
	)
	# Start the input task.
	control_thread = threading.Thread(target=control_task)

	listen_thread.start()
	control_thread.start()