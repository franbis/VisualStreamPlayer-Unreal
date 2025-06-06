import time

import numpy as np

from utils import get_char_match



class Display:
	"""A remote display API."""
	
	def __init__(self, sock, addr, max_heartbeat_interval=10):
		self.sock = sock
		self.addr = addr
		self.heartbeat()
		# The max interval between heartbeats to keep this remote
		# display alive.
		# After that this display gets removed from the belonging
		# video wall's matrix.
		self.max_heartbeat_interval = max_heartbeat_interval
		

	def heartbeat(self):
		"""Called when a heartbeat is received, mark this display
		alive."""
		self.heartbeat_ts = time.time()
		

	@property
	def alive(self):
		"""True if this display is alive."""
		return (time.time() - self.heartbeat_ts) < self.max_heartbeat_interval
		

	def set_frame(self, frame, font_pal_bgr, use_alpha=False):
		"""Convert an np image to its textual representation based
		on the font texture's palette and send it to the remote
		display."""

		# Convert the frame to characters based on the font
		# texture's palette.
		processed_image = np.vectorize(
			lambda color: get_char_match(
				font_pal_bgr,
				color,
				use_alpha=use_alpha
			),
			signature='(3)->(1)'
		)(frame)
		# Make it so all the elements are represented by a byte
		# [S]tring of length [1].
		processed_image = processed_image.astype('S1')
		
		self.sock.sendto(processed_image.tobytes(), self.addr)
			

class VideoWall:
	"""A matrix of remote displays."""
	
	def __init__(self, shape, display_res, name='', max_heartbeat_interval=10):
		self.matrix = np.empty(shape=shape, dtype=list)
		# Initialize each slot in the matrix with an empty list.
		# Each list will contain all the client displays in the
		# respective position in the video wall.
		for e in np.nditer(self.matrix, flags=['refs_ok'], op_flags=['readwrite']):
			e[...] = []
		
		# We assume each tile has the same size.
		self.display_res = display_res
		# The group name.
		self.name = name
		
		# Used for replication when a new client (a new remote
		# display) joins.
		self.last_frame = None
		self.max_heartbeat_interval = max_heartbeat_interval
		

	@property
	def full_res(self):
		"""The resolution calculated based on all the tiles in
		the matrix assuming the wall is 2D."""
		return (
			self.matrix.shape[0] * self.display_res[0],
			self.matrix.shape[1] * self.display_res[1]
		)
		

	def set_frame(self, frame, font_pal_bgr, use_alpha=False):
		"""Store a frame for replication.

		This doesn't automatically send the frame to the remote
		displays, use broadcast_last_frame() for that. This way the
		stored frame can also be replicated to clients who may
		connect later on."""

		self.last_frame = frame
		self.last_font_pal_bgr = font_pal_bgr
		self.last_use_alpha = use_alpha
		

	# We assume the resolution of each display is the same.
	def add_display(self, sock, addr, position=(0, 0), send_last_frame=True):
		"""Add a remote display to the matrix at a
		given position and replicate the stored frame if
		send_last_frame is True."""

		disp = Display(
			sock=sock,
			addr=addr,
			max_heartbeat_interval=self.max_heartbeat_interval
		)
		self.matrix[position].append(disp)
		
		# Replicate the stored frame to the newly created display.
		if send_last_frame and (self.last_frame is not None):
			frame_part = self.last_frame[
				position[0] * self.display_res[0] : (position[0] + 1) * self.display_res[0],
				position[1] * self.display_res[1] : (position[1] + 1) * self.display_res[1]
			]
			disp.set_frame(
				frame_part,
				self.last_font_pal_bgr,
				use_alpha=self.last_use_alpha
			)
		
		
	def broadcast_last_frame(self):
		"""Split the last frame according to the matrix and send it
		to the remote displays."""
		for row in range(self.matrix.shape[0]):
			for col in range(self.matrix.shape[1]):
				
				# Get the last frame tile based on this position in the matrix.
				tile = self.last_frame[
					row * self.display_res[0] : (row + 1) * self.display_res[0],
					col * self.display_res[1] : (col + 1) * self.display_res[1]
				]
				
				dead_displays = []
				for disp in self.matrix[row, col]:
					if disp.alive:
						# This display is still alive, send it the
						# frame tile.
						disp.set_frame(
							tile,
							self.last_font_pal_bgr,
							use_alpha=self.last_use_alpha
						)
					else:
						# We didn't receive a heartbeat from this
						# display recently, queue it for deletion.
						dead_displays.append(disp)
				
				# Remove the dead displays from the matrix.
				for disp in dead_displays:
					self.matrix[row, col].remove(disp)