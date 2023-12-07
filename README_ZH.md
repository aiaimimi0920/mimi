<div id="top"></div>
<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/aiaimimi0920/mimi/">
	<img src="icon.png" alt="Logo" width="100" height="100">
  </a>

  <h3 align="center">MiMi</h3>

  <p align="center">
	一个可以提供无限功能的 mimi ai桌面宠物
	<br />
	<a href="https://github.com/aiaimimi0920/mimi/releases"><strong>立即下载</strong></a>
	<br />
	<br />
	<a href="https://godotforums.org/d/37965-mimi-ai-pet">交流论坛</a>
	  <br />
	 <a href="https://github.com/aiaimimi0920/mimi/blob/main/README.md">English</a>·<a href="https://github.com/aiaimimi0920/mimi/blob/main/README_ZH.md">中文</a>
  </p>
</div>

## 欢迎使用MiMi!
[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/aiaimimi0920/mimi?include_prereleases)](https://github.com/aiaimimi0920/mimi/releases)
[![Godot Engine](https://img.shields.io/badge/Powered%20By-Godot%20Engine%204.0-blue)](https://godotengine.org)
[![License](https://img.shields.io/github/license/aiaimimi0920/mimi)](LICENSE)

### 概览
MiMi 是一个windows平台的桌面ai宠物，基于 [Godot Engine 4.2](https://godotengine.org/) 进行开发。本项目成立的目的，是为了大众都能快速获得ai助力，目标是让你的日常生活工作中的重复内容都可以通过ai宠物来完成。通过插件化的功能设计，结合[GDScript脚本语言](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript\_basics.html)的简便语法，load_resource_pack的动态加载机制，让你可以在运行时热加载不同功能的插件来完成目标。

### 功能特色
* 插件化设计：不同的插件可独立存在，也可定义自己的依赖项和版本，可在运行时动态下载并加载需要的插件。插件作为最小的功能集合，可实现按需下载并加载。
* 统一规范化的消息、设置界面：不同的插件消息弹窗和设置弹窗都是规范化，方便开发者和用户配置。
* 免费ai：免费ai是通过free_ai_adapter插件实现，不需要提供key即可完成ai调用。功能参考[gpt4free](https://github.com/xtekky/gpt4free)
* 增强提问：增强搜索是通过free_vector_adapter插件实现，你可以向量化本地文档后提问的时候增强提问的关联性。注意此插件集合了模型文件，所以有700mb+。
* 插件响应：插件响应模式将可以从共享的插件库和专属的插件库中匹配跟你问题最匹配的插件及方法，下载此插件后自动调用方法后生成响应。
* 插件库：每个人都可以提交不同的插件，并通过注释来声明插件可调用方法。MiMi的可用功能因为插件数量的增多而变多。

## 制作原因
我希望我有一个可以ai帮我处理我日常生活中的常规性活动，比如“到了饭点就给我领好优惠券然后帮我点一个我喜欢吃的外卖”，“下载一首有版权的流行歌曲”，“替我和我女朋友聊聊天”。诚然我可以通过3个软件或者3个自编脚本完成上述3个功能，但是很麻烦呀，而且没有人维护。
不过转念一想，这些功能并不一定只有我需要，其他人也是需要的。所以将每个日常功能设计成一个插件，然后在平台通过对你的问题进行插件方法匹配来选择最优的插件方法调用来完成目标。
实际上就是一个功能给大家一起用，只要大家提供的功能插件够多，那么我的ai机器人就可以做到所有的事情。
这就是 MiMi 最后的目标了。


## 同类差异
- 函数无需定义：MiMi 与 LangChain 和 openai Function calling 存在差异，重点在于同类项目需要在调用的时候就传入函数，对于大部分的终端用户不是很理想，终端用户首先不一定知道怎么传入函数，其次不一定能找到最匹配的插件。对于终端用户而言更在意的是功能实现，而不是函数怎么定义，怎么传入。
- 多功能函数：举个例子就是，对于专注于智能点餐llm的开发者，开发者基于LangChain 或者 openai Function calling 开发了一个智能点餐的app，可能其对于点餐方面有很多的函数定义，但是其不包含播放音乐的函数定义，那么这个时候你跟它说放首歌，它是找不到要调用的函数。通过自动加载插件库中有的插件来完成，你可以做到一个单独点餐app做不到的功能。


## 开始使用

### 下载
MiMi的[发布版本](https://github.com/aiaimimi0920/mimi/releases)中包含全部所需文件

### 更新
启动 MiMi.exe 后会自动检测并下载更新文件。注意更新后会自动重启项目。

### 运行
启动 MiMi.exe 后即可运行项目，注意：第一次运行并提问时需要自动下载free_ai_adapter插件（150mb+），第一次打开文档库功能的时候会下载free_vector_adapter插件（700mb+）。插件下载完成会有消息提示，在消息提示前询问问题可能会出问题或无响应

## 用法示例
- 常规提问：
  - ![base_question](https://github.com/aiaimimi0920/mimi/assets/153103332/5976bec2-c631-4f53-8f4a-a6b6dd5b5104)
- 插件提问：（打开齿轮按钮）
  - ![plugin_question](https://github.com/aiaimimi0920/mimi/assets/153103332/2fcc5635-6a1e-4f0a-8875-ced63a950767)
- 知识库提问：（打开文档按钮）
- 联网提问: (暂未完成)

### 注意事项
- 强制退出项目或者从cmd运行项目后强制杀死项目，可能会导致项目的子进程未顺利退出。可通过任务管理器查询main，并找到对应的项目图标来终止孤儿进程。
- 部分插件依赖的exe是通过pyinstaller打包的，部分意外退出程序的情况会导致解包的temp文件夹未顺利删除，你可以手动删除文件：C:\Users\{user_name}\AppData\Local\Temp\_MEI.*的文件夹


## 主要功能开发路线图
- [x] 核心功能完备
- [x] 支持插件间依赖/加载顺序判断功能
- [x] 服务器平台代码实现
- [x] 云端服务器配置
- [x] 版本检测，自动更新功能
- [x] 插件版本管理
- [x] 统一化消息和设置
- [x] 多种插件实现
- [x] 插件调用机制
- [ ] 整理并将项目开源
- [ ] 插件安全性
- [ ] 插件审核

对于更详细的功能计划，已知问题或功能建议，请访问储存库的 [Issues](https://github.com/aiaimimi0920/mimi/issues) 页面

## 贡献指南

我们非常感谢您有兴趣为本项目贡献源码来让它变得更好。对于代码贡献的流程，我们建议您遵循以下贡献指南：

1. 在您的储存库中Fork本项目
2. 创建一个您准备开发的功能或修复的问题的分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m '添加一些功能'`)
4. 将更改上传到您的储存库 (`git push origin feature/AmazingFeature`)
5. 在本项目储存库中打开一个此分支的Pull Request，来让我们看到并对其进行审阅

## 基于的项目

以下列表列出了本项目所基于的项目，使用本项目时请同时参考它们的许可信息。

* [Godot Engine](https://github.com/godotengine/godot)

## 插件开发
### 插件介绍
- 插件分为基础插件和功能插件。基础插件提供面向api的实现，功能插件提供面向用户的功能实现。
  - 举个例子："我想把文件a上传到aws平台"。那么其实是两个插件完成这个任务的，aws_adapter 提供面向aws的服务，file_list 提供面向用户的服务，ai会识别到file_list中的fs_upload_form最匹配这个方法，并自动填充相关参数，然后调用aws_adapter中对应的功能，注意：调用aws_adapter完成上传文件的相关代码是由file_list插件的开发者自己编写的，而不是ai去猜测如何调用，ai只会猜测如何调用功能插件中的相关函数。
  - 实现原因：因为ai在多轮思考中并不是很聪明，换句话说他其实并不能很聪明的组装基础插件来完成我需要的功能，而功能其实可以类似抽象为普通的日常生活中所可能有的操作，毕竟日常生活中大部分的操作都是重复可定义的。

### 插件开发流程
- 检出本项目的main分支到本地main_project_dir
- 检出本项目的plugin分支到本地plugin_project_dir
- 检出本项目的tools分支到本地tools_dir
  - 本项目对于godot引擎有小幅修改，所以需要用tools中包含的编辑器才可以打开
  - 修改tools_dir/mklink.py 中的 main_project 和 plugin_project 为main_project_dir 和 plugin_project_dir。此脚本的作用是将main project 中的内容通过软链接的形式同步到plugin_dir中
- 根据插件类型：
  - 功能插件：
    - gd代码存放点: plugin_project_dir/plugin/your_plugin_name/version/
    - 插件打包的时候只会打包存放目录的内容，不会打包任何外部内容。
    - 模板：core/api/plugin_api/plugin_template/template/ 或者其他的插件
  - 基础插件
    - 不需要外部程序(纯gd开发)：
      - gd代码存放点: plugin_project_dir/external_service_adapter/your_plugin_name/version/
      - 插件打包的时候只会打包存放目录的内容，不会打包任何外部内容。
      - 模板: core/api/plugin_api/service_plugin_no_program_template/external_service_adapter/template/ 或者其他的插件
    - 需要外部程序(依赖其他的外部程序或者链接库)：
      - gd代码存放点: plugin_project_dir/external_service_adapter/your_plugin_name/version/
      - 外部程序或者库存放点：plugin_project_dir/external_service/your_plugin_name/version/
      - 插件打包的时候只会打包存放目录的内容，不会打包任何外部内容。注意如果你external_service包含过程代码，请在打包的时候先删除，比如：你的外部程序是用python开发的exe程序，你将external_service/your_plugin_name/version/作为你的代码存放点，那么你应该在打包的时候只保留外部程序在external_service/your_plugin_name/version/中，临时删除原始的python代码，否则你的python代码也会打包到插件包中。
      - 模板: core/api/plugin_api/service_plugin_template/external_service_adapter/template/ 或者其他的插件
- 插件上传：
  - 可以通过在编辑器中运行主场景，然后输入指令/packing_bot generate_plugin_file your_plugin_name 触发打包与上传流程。
- 请注意：本项目不要求你公开你插件的源代码，所以你可以是以闭源插件的形式上传插件。如果你有兴趣将你的插件代码合并到plugin分支中，我们也十分欢迎。

### 插件请求
急寻贡献者
- 下载插件：现在的下载逻辑其实是通过godot的http表单下载实现的，没有多线程的加持就是很慢。希望贡献者可以优化下载速度，可行的参考方案：1. 在godot中通过多线程+分块来下载内容 2. 通过在插件中集成xdown等下载软件，并调用软件来加快下载速度。
- 声音插件：希望MiMi可以发出让人开心的声音，高木同学最佳！
- 模型优化：现在服务端使用的是paraphrase-multilingual-MiniLM-L12-v2 模型作为插件匹配，使用此模型的原因是因为我希望插件方法搜索是多语言匹配的。但是现在的插件方法匹配度有点问题，比如有的时候我搜索“下载音乐稻香”，它会给我返回“search_music”。“download_music”的向量化前的字符文本为‘根据“歌曲名”、“歌手名”、“下载地址”下载歌曲’；“search_music”的向量化前的字符文本为‘根据“歌曲名”和“歌手名”检索歌曲’。按理来说download_music应该更加匹配，但是根据向量距离，它返回了search_music。所以希望有人优化一下模型。


## 项目许可

项目基于LGPL-3.0许可进行开源，具体内容请参见[LICENSE文件](https://github.com/aiaimimi0920/mimi/blob/main/LICENSE)

## 联系信息

aiaimimi - aiaimimi0920@gmail.com

项目社区: [https://godotforums.org/d/37965-mimi-ai-pet](https://godotforums.org/d/37965-mimi-ai-pet)

项目开源地址: [https://github.com/aiaimimi0920/mimi](https://github.com/aiaimimi0920/mimi)


## 赞助:
* 给此仓库一个小小的  Star~ star this repository

## 🙇 致谢
如果没有社区已经提供的优秀软件的帮助，MiMi是不可能构建的。非常感谢。
- [RainyBot](https://github.com/Xwdit/RainyBot-Core)
- [godot](https://github.com/godotengine/godot)
- https://github.com/gdquest-demos/godot-4-3D-Characters
- [gpt4free](https://github.com/xtekky/gpt4free)
- [chroma](https://github.com/chroma-core/chroma)
- [playwright](https://github.com/microsoft/playwright)


## 相关链接
此处提供了一些可能与本项目有关，或对您有帮助的链接
* [Godot使用文档](https://docs.godotengine.org/en/latest/)
* [GDScript语言教程](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/)
* [Godot类参考API](https://docs.godotengine.org/en/latest/classes/index.html)
