# Running the Examples

**NOTE**: &nbsp;This guide assumes you're on Windows.
<br>

## Packages

In `examples\` you can find the source code for 3 .u packages, a .utx and a .unr map in which the packages are used.
<br>
Here's what each .u package does:

1. *VSPPaletteFonts* - Stores a font, its texture and some background textures, all using the same palette
1. *VSPMutExample* - Contains a mutator to let players communicate with the example streamer software
1. *VSP469eFix* - Contains a `VSPDisplay` subclass that can be used as a workaround to [this issue](https://github.com/OldUnreal/UnrealTournamentPatches/issues/1834)

### Setting up the packages

#### Requirements

* Python (needed to generate font textures)

<br>

**NOTE**: UCC doesn't recognize paths that contain spaces.

1. [Setup the Python virtual environment](#setting-up-the-streamer)
1. [Compile the core packages](/README.md#build-instructions) if you haven't
1. Rename `make.ini.template` (within `examples\packages\`) to `make.ini`, open it and set `Paths` (in the section `[Core.System]`) with the path to the game core packages
1. Open a terminal within `examples\` and set the `GAME_PATH`, `TEXTURES_PATH`, `MAPS_PATH` environment variables. (E.g. `set GAME_PATH=C:\Game\Path`)
1. Set the `PYTHON_VENV` environment variable with the path to the streamer Python virtual environment.
1. Send the command `setup.bat`. This should end up creating the packages in the `System` directory of the game

**NOTE**: It's not necessary with 469 servers/clients but you may want to give a unique name to the packages.

<br>

## Streamer

### Requirements

* Python

### Setting up the Streamer

1. Open a terminal within `streamer\` and create a virtual environment by running `python -m venv .venv`
1. Enter the virtual environment by sending the command `.venv\Scripts\activate`
1. Install the dependencies by sending the command `pip install -r requirements.txt` (or `pip install -r requirements_extra.txt` if you wish to stream YouTube videos or OpenAI generated images)

### Running the Streamer

1. Open a terminal within `streamer\` and enter the virtual environment by sending the command `.venv\Scripts\activate`
1. Send the command `py streamer.py --host 0.0.0.0` to run the streamer and allow it to take commands from anywhere
1. The streamer will print the host and port it is listening to, if you wish for it to communicate with online clients you need to open that same port on your router

<br>

# Testing the Examples

### Initialization

* [Run the streamer software](#running-the-streamer) before starting the map, as the map will send information about the displays layout to the streamer software at startup.
* Start the map `VSPExampleMap1` with the `VSPMutExample` mutator. From within the game you can open the map this way: `open VSPExampleMap1?Mutator=VSPMutExample.VSPMutExample`. Or you can start a server using ucc this way: `ucc server VSPExampleMap1?Mutator=VSPMutExample.VSPMutExample`

### Testing

The map contains 3 display groups, be aware that `group3` uses a multi-screen layout. `group2` will be used for this guide, which is the display in the middle.

You can send commands to the streamer either from the command prompt or remotely using the `mutate` in-game command:
* From the command prompt: `stream ../examples/media/indexed_color/palette_tex_color_1.bmp --vid ../examples/media/for_display/color_cube_63x63.gif --use_alpha -g group2`
* In-game: `mutate stream --vid ../examples/media/for_display/color_cube_63x63.gif --use_alpha -g group2`

You can view the streamer help by sending the command `py streamer.py --help` or `help` if you've started the streamer already.