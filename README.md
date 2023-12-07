<div id="top"></div>
<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/aiaimimi0920/mimi/">
	<img src="icon.png" alt="Logo" width="100" height="100">
  </a>

  <h3 align="center">MiMi</h3>

  <p align="center">
  MiMi is an AI desktop pet that can provide unlimited features.
	<br />
	<a href="https://github.com/aiaimimi0920/mimi/releases"><strong>download now</strong></a>
	<br />
	<br />
	<a href="https://godotforums.org/d/37965-mimi-ai-pet">Communication Forum</a>
	  <br />
	 <a href="https://github.com/aiaimimi0920/mimi/blob/main/README.md">English</a>·<a href="https://github.com/aiaimimi0920/mimi/blob/main/README_ZH.md">中文</a>
  </p>
</div>

## Welcome to MiMi!
[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/aiaimimi0920/mimi?include_prereleases)](https://github.com/aiaimimi0920/mimi/releases)
[![Godot Engine](https://img.shields.io/badge/Powered%20By-Godot%20Engine%204.0-blue)](https://godotengine.org)
[![License](https://img.shields.io/github/license/aiaimimi0920/mimi)](LICENSE)

### Overview
MiMi is a desktop AI pet for the Windows platform, developed using [Godot Engine 4.2](https://godotengine.org/). The purpose of this project is to provide AI assistance to the general public, with the goal of enabling users to quickly complete repetitive tasks in their daily work and life using an AI pet. Through the design of a plugin system, combined with the simplicity of the [GDScript scripting](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript\_basics.html) language, and the dynamic loading mechanism of load_resource_pack, you can dynamically load different plugins at runtime to achieve various goals.

### Features
* Plugin-based design: Different plugins can exist independently and define their own dependencies and versions. They can be dynamically downloaded and loaded at runtime. Plugins serve as the smallest functional units, allowing on-demand downloading and loading.
* Unified and standardized messaging and settings interface: Different plugins' message pop-ups and setting pop-ups are standardized, making it easy for developers and users to configure.
* Free AI: Free AI is implemented through the free_ai_adapter plugin, requiring no key to complete AI calls. Functionality is similar to [gpt4free](https://github.com/xtekky/gpt4free).
* Enhanced questioning: Enhanced search is implemented through the free_vector_adapter plugin. You can enhance the relevance of questions by vectorizing local documents when asking questions. Note that this plugin includes model files, so it's around 700 MB+.
* Plugin response: The plugin response mode will match the most suitable plugins and methods from the shared plugin library and exclusive plugin library based on your questions. After downloading the plugin, it automatically calls the method to generate a response.
* Plugin library: Everyone can submit different plugins and declare callable methods through comments. MiMi's available features grow as the number of plugins increases.


## Motivation
I wanted an AI that could help me with routine activities in my daily life, such as "fetching coupons for me when it's mealtime and then ordering takeout for me," "downloading a copyrighted popular song," or "chatting with my girlfriend on my behalf." While I could achieve these tasks with three different software programs or three self-coded scripts, it was cumbersome, and there was no one to maintain it.
However, upon further thought, these functionalities may not be unique to me; others might need them too. Therefore, designing each daily function as a plugin and then using the platform to match plugin methods to your questions to select the optimal plugin method for achieving the goal.
In essence, it's a feature for everyone to use together. As long as there are enough functional plugins provided by everyone, my AI robot can do everything.
That's the ultimate goal of MiMi.

## Differences from Similar Projects
- No need to define functions: MiMi differs from LangChain and openai Function calling in that similar projects require passing functions at the time of calling, which is not ideal for most end-users. End-users may not know how to pass functions, and they may not be able to find the most suitable plugin. For end-users, functionality is more important than defining and passing functions.
- Multifunctional functions: For example, for a developer focusing on developing an intelligent ordering app, based on LangChain or openai Function calling, the developer may have many function definitions related to ordering, but the app may not include a function definition for playing music. In this case, if you ask it to play a song, it won't find the function to call. By automatically loading plugins available in the library, you can achieve functionality that a standalone ordering app cannot.

## Getting Started

### Download
MiMi的[release versions](https://github.com/aiaimimi0920/mimi/releases) include all the necessary files.

### Update
Launching MiMi.exe will automatically detect and download update files. Note that the project will restart automatically after the update.

### Run
Launch MiMi.exe to run the project. Note: The first time you run and ask a question, it will automatically download the free_ai_adapter plugin (150 MB+). The first time you open the document library function, it will download the free_vector_adapter plugin (700 MB+). There will be a message prompt when the plugin download is complete. Asking questions before the message prompt may cause issues or no response.

## Usage Examples
- General questioning:
  - ![base_question](https://github.com/aiaimimi0920/mimi/assets/153103332/5976bec2-c631-4f53-8f4a-a6b6dd5b5104)
- Plugin questioning: (open the gear button)
  - ![plugin_question](https://github.com/aiaimimi0920/mimi/assets/153103332/2fcc5635-6a1e-4f0a-8875-ced63a950767)
- Knowledge base questioning: (open the document button)
- Internet questioning: (not yet completed)

### Notes
- Forcibly exiting the project or forcibly killing the project after running it from the cmd prompt may result in the project's subprocess not exiting smoothly. You can use the task manager to find main and terminate the orphan process by finding the corresponding project icon.
- Some plugins depend on executables packaged with pyinstaller. Unexpected exits may lead to the unpacked temp folder not being deleted smoothly. You can manually delete the files in the folder: C:\Users\{user_name}\AppData\Local\Temp\_MEI.*.


## Main Function Development Roadmap
- [x] Core functionality completion
- [x] Support for plugin dependencies/loading order determination
- [x] Server platform code implementation
- [x] Cloud server configuration
- [x] Version detection, automatic update functionality
- [x] Plugin version management
- [x] Standardized messaging and settings
- [x] Implementation of various plugins
- [x] Plugin calling mechanism
- [ ] Organize and open-source the project
- [ ] Plugin security
- [ ] Plugin examine

对于更详细的功能计划，已知问题或功能建议，请访问储存库的 [Issues](https://github.com/aiaimimi0920/mimi/issues) 页面
For more detailed feature plans, known issues, or feature suggestions, please visit [Issues](https://github.com/aiaimimi0920/mimi/issues) in the repository.

## Contribution Guide

We greatly appreciate your interest in contributing source code to this project to make it better. For the code contribution process, we recommend that you follow the contribution guide below:

1. Fork this project in your repository.
2. Create a branch for the feature or issue you plan to develop (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push your changes to your repository (`git push origin feature/AmazingFeature`)
5. Open a Pull Request in this project's repository for this branch to let us see and review it.

## Based on Projects

The following list includes the projects this project is based on. When using this project, please also refer to their license information.

* [Godot Engine](https://github.com/godotengine/godot)

## Plugin Development
### Plugin Introduction
- Plugins are divided into basic plugins and functional plugins. Basic plugins provide API implementations, while functional plugins provide user-facing functionality.
  - For example, "I want to upload file A to the AWS platform." In reality, two plugins complete this task: aws_adapter provides AWS services, and file_list provides user services. The AI will recognize that fs_upload_form in file_list is the most suitable method for this task, automatically fill in the relevant parameters, and then call the corresponding function in aws_adapter. Note: The code to call aws_adapter to complete the file upload is written by the developer of the file_list plugin, not the AI trying to guess how to call it. The AI only guesses how to call the relevant functions in the functional plugins.
  - Reason for implementation: Because AI is not very smart in multi-turn thinking. In other words, it cannot cleverly assemble basic plugins to complete the functionality I need. However, functionality can be abstracted similarly to common operations in daily life, as most operations in daily life are repetitive and definable.

### Plugin Requests
Urgently seeking contributors
- Download plugin: The current download logic is implemented through Godot's HTTP form, and it is slow without multi-threading. Contributors are requested to optimize download speed. Feasible reference solutions: 1. Download content in Godot through multi-threading + chunking. 2. Integrate download software such as xdown into plugins and call the software to speed up downloads.
- Sound plugins: Hoping MiMi can make cheerful sounds, with Takagi as the best choice!
- Model optimization: The current server uses the paraphrase-multilingual-MiniLM-L12-v2 model for plugin matching. The reason for using this model is that I want plugin method search to be multilingual. However, there is an issue with the current plugin method matching. For example, when searching for "download music 稻香," it returns "search_music." The pre-vectorization text for "download_music" is 'Download songs based on "song name", "artist name", and "download address".' The pre-vectorization text for "search_music" is 'Search for songs based on "song name" and "artist name".' In theory, "download_music" should be a better match, but based on vector distance, it returns "search_music." So, hoping someone can optimize the model.

## Project License

The project is open-source under the AGPL-3.0 license. For specific details, please refer to the [LICENSE文件](https://github.com/aiaimimi0920/mimi/blob/main/LICENSE)

## Contact Information

aiaimimi - aiaimimi0920@gmail.com

Project Community: [https://godotforums.org/d/37965-mimi-ai-pet](https://godotforums.org/d/37965-mimi-ai-pet)

Project Open Source Repository: [https://github.com/aiaimimi0920/mimi](https://github.com/aiaimimi0920/mimi)


## Donate:
* Give this repository a small Star~ star this repository

## 🙇 Acknowledgements
mimi couldn't have been built without the help of great software already available from the community. Thank you!
- [RainyBot](https://github.com/Xwdit/RainyBot-Core)
- [godot](https://github.com/godotengine/godot)
- https://github.com/gdquest-demos/godot-4-3D-Characters
- [gpt4free](https://github.com/xtekky/gpt4free)
- [chroma](https://github.com/chroma-core/chroma)
- [playwright](https://github.com/microsoft/playwright)


## Related Links

Here are some links that may be related to this project or helpful for you:

* [Godot使用文档](https://docs.godotengine.org/en/latest/)
* [GDScript语言教程](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/)
* [Godot类参考API](https://docs.godotengine.org/en/latest/classes/index.html)
