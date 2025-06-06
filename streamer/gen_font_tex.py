"""
Generates an image with a desired palette depicting a representation
of its own palette in a way that UE1 FontFactory can successfully interpret
as a font texture where to find glyphs from to construct a font.
The pixels structure is kept to the bare essential.
"""

import sys
import os
import argparse

from PIL import Image

import utils



# Main program arguments.
argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('--help', action='help', help='Show this help message and exit')
argparser.add_argument('indexed_color_img', type=str, help='Path of the indexed color image the palette will be copied from')
# Alpha color included.
# We use 96 glyphs by default because of how UE1 maps font characters
# when reading them from an imported texture.
argparser.add_argument('--glyph_count', '--glyphs', type=int, default=96, help='Glyphs count (alpha character included)')
argparser.add_argument('--out_font_tex', '--out', type=str, default='palette_font_tex.bmp', help='Path of the generated font texture')
argparser.add_argument('--verbose', '-v', action='store_true')

args = argparser.parse_args(sys.argv[1:])


# Extract the palette from the source image.
palette = Image.open(args.indexed_color_img).getpalette()

if not palette:
	print('The input image must be an indexed color image.')
	exit(1)


glyph_count = args.glyph_count

# Make the width enough to contain all the glyphs and grid columns
# between them.
# The image resolution must be a power of 2 like for UE1 textures,
# so extend it if needed.
width = utils.find_next_power_of_2((glyph_count * 2) + 1)
# 4 is the minimum height for a font texture.
height = 4

# Create an image in [P]alette mode (indexed color image).
font_tex = Image.new('P', (width, height))
# The font texture must have the palette the glyphs represent.
font_tex.putpalette(palette)


# Begin drawing.

pixels = font_tex.load()

# By default the whole image uses the first color in the palette
# as background, it will also be used in UE1 when masking as
# transparent background.

# Draw a solid rectangle onto which the colors/glyphs will be
# overimposed. This rectangle will therefore look like a grid in
# the end.
for x in range((glyph_count * 2) + 1):
	pixels[x, 0] = len(palette) - 1
	pixels[x, 1] = len(palette) - 1
	pixels[x, 2] = len(palette) - 1

# Overimpose the colors/glyphs onto the separator.
# We separate each glyph by 1px.
pixels[1, 1] = 0
for color_idx in range(1, glyph_count):
	pix_idx = (color_idx * 2) + 1
	pixels[pix_idx, 1] = color_idx


font_tex.save(args.out_font_tex)
print(f'Font texture saved at "{os.path.abspath(args.out_font_tex)}".')