import os
import argparse
import subprocess
import shutil
from pathlib import Path
main_project = "C:/Users/Public/nas_home/VMe"
plugin_project = "C:/Users/Public/nas_home/VMe_Plugin"

## if you want to change use_main_project_array or use_plugin_project_array
## Please modify both the main's gitgnore and the plugin's gitgnore at the same time
use_main_project_array = [
    "addons",
    "core",
    "game_settings",
    "update",
    "gui",
    "models",
    "modules",
    "resources",
    "viewer",
    "export_presets.cfg",
    "export.cfg",
    "icon.svg",
    # "project.godot",
]


use_plugin_project_array = [
    # "external_service/free_ai_adapter",
    "external_service_adapter/pck_adapter",
    "external_service_adapter/ipfs_adapter",
    "external_service_adapter/aws_adapter",
    "external_service_adapter/cloudflare_adapter",
    "plugin/file_list",
    "plugin/free_ai_bot",
    "plugin/update_bot",
]

def link_all_folder():
    for file_name in use_main_project_array:
        link = os.path.abspath(os.path.join(plugin_project, file_name))
        target = os.path.abspath(os.path.join(main_project, file_name))
        link_folder(link, target)
    for file_name in use_plugin_project_array:
        target = os.path.abspath(os.path.join(plugin_project, file_name))
        link = os.path.abspath(os.path.join(main_project, file_name))
        link_folder(link, target)

def link_folder(link, target):
    p = Path(link)
    if p.exists():
        if p.is_symlink():
            if p.is_dir():
                p.rmdir()
            else:
                p.unlink()
        else:
            if p.is_dir():
                shutil.rmtree(link,True)
            else:
                p.unlink()

    if Path(target).exists():
        p.symlink_to(target, target_is_directory=Path(target).is_dir())

if __name__ == "__main__":
    print("Because this script involves deleting local files, please submit the relevant local modifications first before executing this script")
    print("The script needs to be executed with administrator privileges, otherwise the link cannot be created")
    choice = input("yes or no:")
    if choice == "yes":
        print("Perform the next step")
        link_all_folder()
        print("Created symbolic link success")
    else:
        print("Cancel the operation")
    
