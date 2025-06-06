# VisualStreamPlayer

A real-time media player for Unreal Engine 1 written in UnrealScript which draws frames on a *ScriptedTexture*. No audio is played.
<br>
Includes a streaming software.
<br>

---

<br>

<!--<img src="examples/media/demo/still_img_demo.avif" width="128" alt="Streaming a local image" />

*Streaming a local image*

<br>

<img src="examples/media/demo/vid_demo.avif" width="128" alt="Streaming a local video" />

*Streaming a local video*

<br>-->

<img src="examples/media/demo/transparent_vid_demo.avif" width="128" alt="Streaming a local video with alpha clip" />

*Streaming a local video with alpha clip*

<br>

<img src="examples/media/demo/yt_demo.avif" width="128" alt="Streaming a video from the web" />

*Streaming a video from the web*

<br>

<!--<img src="examples/media/demo/ai_demo.avif" width="128" alt="Streaming an AI-generated image" />

*Streaming an AI-generated image*

<br>-->

<img src="examples/media/demo/video_wall_demo.avif" width="128" alt="Multi-screen support" />

*Multi-screen support*

<br>


## How does it work?

Streaming and drawing colored pixels requires too much data to receive for an old engine and too much computation to process it.

To overcome this, a *font* where *glyphs* are individual *colored pixels* can be used.
<br>
This way the media streamer just needs to send a character sequence where each character is represented by a colored pixel in the font.
<br>
Thanks to this we can draw lines of pixels rather than each pixel individually.

The colored font is created with `FontFactory` (a UE native class), which takes an *image*, where pixels are arranged to be interpreted as font *glyphs*, and converts it to a *font* which can used in-game.
<br>
This means we have to generate an image where each colored pixel is associated with a character according to how `FontFactory` interprets the pixels structure.

When calling `drawText()` the `ScriptedTexture` palette will be used. To prevent miscolorization we sync the palettes among textures and fonts.

<br>

## Usage instructions

### For mappers

As a mapper, you have to make sure display textures are aligned to fit the whole frame, display surfaces are aligned to each other in case of multi-screen setups and that textures are using the correct color tables.
<br>
You can find some setups within `examples\` and an example map.

Here are the steps for a simple single-display setup.
<br>
After deciding on what *color palette* to use:

1. Create an image with the chosen *palette* that will be used for the display and import it as a *Texture*
1. Create a *ScriptedTexture* (ideally 64x64 on 469) and assign the previously created *Texture* to `sourceTexture`
1. Create a map and apply the *ScriptedTexture* on a surface
1. Align the UV to fit a whole frame on the surface. Keep in mind that the actual size of the drawn frame will be 1 row and 1 column less for technical reasons 
1. Add a `VSPDisplayManager` and set at least these properties as following:

    * palTex - Assign the Texture
    * palFont - Assign the Font
    * scrTex - Assign the ScriptedTexture

### For server owners

For the sake of this guide, it's assumed you're going to use the example streamer from this project. Therefore, refer to the section *Streamer* in [Running the Examples](/examples/examples.md#streamer).

<br>

## Build Instructions

This guide is about compiling the core packages. If, instead, you are looking to setup the streamer, refer to the section *Streamer* in [Running the Examples](/examples/examples.md#streamer).
<br>

You can either copy the packages from `packages\` to the game root directory and build them the way you'd build any other package, or you can follow the steps below (on Windows).

**NOTE**: UCC doesn't recognize paths that contain spaces.

1. Rename `make.ini.template` (within `packages\`) to `make.ini`, open it and set `Paths` (in the section `[Core.System]`) with the path to the game core packages
1. Open a terminal within `packages\` and set the `GAME_PATH` environment variable: `set GAME_PATH=C:\Game\Path`
2. Run `make.bat`. This should create the package in the `System` directory of the game

**NOTE**: It's not necessary with 469 servers/clients but you may want to give a unique name to the package.