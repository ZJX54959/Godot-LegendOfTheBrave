# Godot-LegendOfTheBrave

这是根据b站教程[BV1SP411m7aj](https://www.bilibili.com/video/BV1SP411m7aj)@timothyqiu的Godot 4教程《勇者传说》做下来的一个项目，作为godot引擎入门
* 当前版本Godot4.4

 > 所有图像资源等我大概都不具备版权。因此本项目仅供娱乐

---

 ### 目前进度eps.15（场景切换/新场景）已完成

 闲来无事，在照着其制作的基础上，又凭借着兴趣搞了点自己想要的功能。目前已实现的有：

  - **InputBuffer实现**。
  也即输入缓存。实现了对0.5秒内按键输入的记录，实现了对长短按以及特定时间区间内按键的记录与判断。$_{由于莫名其妙的bug手动排除了所有godot自带的以“ui\_”开头的动作}$

  - **远程攻击实现**。[按<kbd>K/鼠标右键</kbd>射击] 
  分别实现了bullet类和shooter类。 bullet类下创建了四个继承场景```arrow```、```lightning```、```grapple```、```laser```。分别对应箭矢（有初速受重力影响）、闪电（纯播放动画）、钩爪、激光，实现方式各不相同，私以为是很好的bullet类使用方式示例。shooter为发射子弹的类，实现了子弹的创建与发射。外部调用可用shooter.shoot_config()完成发射子弹的配置，并调用shooter.shoot()完成子弹的创建与发射。

  - **InteractiveGrass实现**。
  实现了草地与人物的交互。来自[BV1uEr1YXE9t](https://www.bilibili.com/video/BV1uEr1YXE9t)搬运By [xcount](https://space.bilibili.com/351607965)

  - **伤害飘字实现**。
  实现了伤害飘字。来自[BV18pAKeAE5R](https://www.bilibili.com/video/BV18pAKeAE5R)By [无所不能的咲夜](https://space.bilibili.com/2706229)
  
  - **新enemy实现（Fairy）**。
  实现了敌人的创建与移动。它能发射箭矢（哦对我给箭矢改成别的玩意儿了），还挺萌（猛？）的嘞。*寻路还有点问题*

  - **钩爪实现**。[按<kbd>E/鼠标中键</kbd>射击] 
  实现了钩爪的创建与发射。如上所述用的是bullet类。按<kbd>space</kbd>键施加三倍力。

  - **激光实现**。[长按<kbd>K/鼠标右键</kbd>射击] 
  实现了激光的创建与发射。如上所述用的是bullet类。~~采用了对象池，但感觉没什么必要~~

  - **DP(623)、QCF(236)、DD(22)命令实现**。[按<kbd>623/236</kbd>+<kbd>K/鼠标右键</kbd>执行DP/QCF，按<kbd>22</kbd>+<kbd>L/鼠标右键</kbd>执行DD] 
  DP：直接进入Attack3状态；QCF：进入（改用输入缓存后就一直弃用到现在的）Attack_Combo状态；22：在鼠标处发射雷

  - **攻击种类实现**。
  说是这么说，但反正现在也没几种攻击，算是预留个方法吧
---

### To-Do list

- 蹲姿、盾姿、蓄力姿等

- 空中攻击

- ~~交互（eps14）~~

- ~~场景切换+新场景（eps15）~~

  - ~~貌似需要上一点为基础~~

- 菜单界面（eps23、eps24？）

  - 背包、技能、装备、属性、天赋树、合成、任务、成就、设置、存档、退出之类的

- 标题界面（eps20、eps21）

- 音乐&音效（eps22）

- 新美术素材！现在的美术素材和音乐素材完全不够！虽然是个练手作

- 完善打击感。主要就该弄打击感。打击感这块儿不能不弄啊。打击感才是最重要的

- Fix BUGS！！！

- and more...

---

#### 碎碎念啥的

很多内容由AI辅助完成。赞美DeepSeek-R1，赞美Cursor。

最近[AiC](https://aicwiki.com/zh/home)[0.27g](https://www.bilibili.com/read/cv40671724/)不是更新了吗。趁更新玩了几天回坑了结果玩着迷了。感觉人家是做的真好啊...暂时以AiC为目标吧