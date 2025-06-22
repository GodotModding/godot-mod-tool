<div align="center">

# Godot Mod Loader Development Tool

<img alt="Godot Mod Loader Devtool Logo" src="./icon.png" width="256" />

<br />
<br />

The mod tool aims to improve the development experience when creating [Godot ModLoader](https://github.com/GodotModding/godot-mod-loader) mods.

</div>





## Features:
- Simple mod zipping process with 7zip to ensure proper format for ModLoader
    - Steam Workshop
    - Thunderstore (soon™)
- Easy editing of the mod's `manifest.json` file, with validation
- Json Schema editor for the mod's configuration settings, with validation (soon™)
- Advanced right click context menu
    - Create new script override file
    - Create new asset overwrite
- Create a simple mod skeleton with a single click
- Easy installation as an addon (from the AssetLib)


## Installation
1. Download the latest release from the [releases page](https://github.com/GodotModding/godot-mod-tool)
1. Add the `mod_tool` folder to your Godot project's `addons` folder
1. Enable the addon in the Godot editor's Project Settings

Even more convenient, you can install the addon from the AssetLib.
1. Go to the AssetLib tab
1. Search for [`mod loader dev tool`](https://godotengine.org/asset-library/asset?filter=mod+loader+dev+tool)
1. Click `Install` on the addon
1. Enable the addon in the Godot editor's Project Settings


## Usage
Click the <kbd>Mod Tool</kbd> button in the Godot editor's top menu bar to open the Mod Tool window.

Right click on a file in the FileSystem dock to get context actions.
