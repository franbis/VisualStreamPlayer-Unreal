import argparse



# Main program arguments.
main_parser = argparse.ArgumentParser(add_help=False)
main_parser.add_argument('--help', action='help', help='Show this help message and exit')
main_parser.add_argument('--host', type=str, default='127.0.0.1')
main_parser.add_argument('--port', type=int, default=6789)
main_parser.add_argument('--verbose', '-v', action='store_true')


# Commands and arguments that can be received by either clients or stdin
# at run-time.

# CMD: send

cmd_stream_parser = argparse.ArgumentParser(prog='stream', add_help=False)
cmd_stream_parser.add_argument('--help', action='help', help='Show this help message')
cmd_stream_parser.add_argument('--group', '-g', type=str, default='', help='Video wall group')

cmd_stream_mutex_group = cmd_stream_parser.add_mutually_exclusive_group(required=True)
cmd_stream_mutex_group.add_argument('--img_path', '--img', type=str, default='', help='Still image path')
cmd_stream_mutex_group.add_argument('--vid_path', '--vid', type=str, default='', help='Video path or YouTube video URL')
cmd_stream_mutex_group.add_argument('--use_camera', '--cam', action='store_true', help='Use the camera')
cmd_stream_mutex_group.add_argument('--ai_prompt', '--ai', type=str, default='', help='AI image prompt (OPENAI_API_KEY needs to be set as environment variable)')

# We use 96 glyphs by default because of how UE1 maps font characters
# when reading them from an imported texture.
cmd_stream_parser.add_argument('--glyph_count', type=int, default=96, help='Glyphs count (alpha character included)')
cmd_stream_parser.add_argument('--use_alpha', action='store_true', help='Use the alpha color')
cmd_stream_parser.add_argument('font_tex_path', type=str, help='Font texture path')