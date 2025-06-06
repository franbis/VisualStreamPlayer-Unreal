import math

import numpy as np



def find_next_power_of_2(n):
	return (2 ** math.ceil(math.log(n, 2))) if n > 1 else 2


def get_char_match(font_pal_bgr, color, use_alpha=False):
	"""Get the character from within a font texture based on its
	palette representing the color which is the closest to the given
	color."""

	# Calculate the magnitudes to get the closest color in the palette.
	dists = np.sqrt(np.sum((font_pal_bgr - color) ** 2, axis=1))
	closest_idx = np.argmin(dists)
	# Convert to char.
	# Use only the glyphs after the "space" char as it is the first char
	# to be processed in a font texture.
	return np.array([chr(closest_idx + ord(' ') + (not use_alpha))])