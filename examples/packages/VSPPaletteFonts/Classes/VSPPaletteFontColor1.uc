//=============================================================================
// VSPPaletteFontColor1.
// Description: Imports a "palette font" and its texture.
//				Also contains some backgrounds and debug borders.
//=============================================================================
class VSPPaletteFontColor1 extends Info;


#exec FONT IMPORT FILE=Fonts/palette_font_color_1.bmp NAME=sp_palette_font_color_1
#exec TEXTURE IMPORT FILE=Fonts/palette_font_color_1.bmp NAME=sp_palette_tex_color_1 MIPS=OFF

#exec TEXTURE IMPORT FILE=Textures/border_1_color_1.bmp NAME=sp_palette_tex_color_1_border_1 MIPS=OFF
#exec TEXTURE IMPORT FILE=Textures/black_color_1.bmp NAME=sp_palette_tex_color_1_black MIPS=OFF
#exec TEXTURE IMPORT FILE=Textures/scrabble_1_color_1.bmp NAME=sp_palette_tex_color_1_scrabble_1 MIPS=OFF