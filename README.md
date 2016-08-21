# Exor
我还不知道该如何定义它。它像一个操作系统一样能够引导，也有一个最基本的用户交互接口，也能通过一些命令来让它做你要让它做的事情，但是它和一个操作系统非常不一样，以至于用『操作系统』命名它非常不恰当。所以姑且称之为『系统』。

# 初衷/Motivation/Rationale
和所有打算自己实现一个操作系统的朋友一样，受Linus Torvalds 独立搞出Linux内核的故事所激励，希望能全面了解计算机的硬件结构，就是被现有的操作系统所隐藏的各种细节，也希望弄明白一个操作系统到底是如何工作的。目前操作系统的架构以及设计实现也非常成熟，大部分学校的计算机系都开设操作系统课程，即使你没有自己实现操作系统，也能明白它如何实现内存和其他硬件资源的管理，进程调度，进程间通信，以及网络等等。你只要遵循所学到的知识，读源码，看教程，然后从一个汇编代码的bootloader写起，逐步加载一个用C写的内核镜像，包括虚拟内存管理，调度器，等等。目前大部分能够找到的homebrew操作系统源码，大概都遵循这个套路。但是有一些事情让我觉得我有必要做一些不同的尝试。

1. **一个不同的汇编语言开发方式**
 正如你看到Exor里所有的代码都是用汇编写的一样。在十年前，我上大二的一门《微机控制》课程，相当于自动化系的《计算机体系结构》，在上这门课的时候开始大量使用汇编，基本上是相当于把一台计算机当作一个Arduino，控制各种周边设备。那个时候发现基本所有的汇编器都具有强大的宏定义功能，通过这些宏定义，可以写出高度模块化且可重用的代码。但是很多年过去了，并没有人花心思研究如何将高级语言的programming conventions应用到汇编中。GitHub上也有不少用纯汇编写的操作系统项目，但是和以往所有对汇编语言的批判一样，非常混乱且很难读懂。

 直到我看到了一个项目叫做[JonesForth](http://git.annexia.org/?p=jonesforth.git;a=summary)。Forth是一个很低级且有相当长历史的语言，包含这套语言本身的定义，以及实现对这个语言的解释器的设计细节。Exor本身的设计思路也深受Forth影响，会在下文更详细地阐明。项目代码沿用了DEK的文档式编程的思路，介绍了一种极其牛逼的汇编代码组织思路，同时也构成了Forth实现的基础。大体思路是，你需要为自己建立一套infrastructure，这个基础设施不一定直接和项目的逻辑有关，但是却能够为之后的代码带来极大的便利和灵活。一言以蔽之就是『磨刀不误砍柴工』。 所以这个项目本身是我学习汇编语言，以及试验这种编程风格的结果。

2. **Forth是什么以及为什么要用Forth**
 当然关于Forth更具体更官方的描述可以参看[Wikipedia上的条目](https://en.wikipedia.org/wiki/Forth_(programming_language))，我简单地描述一下。Forth作为一种语言，要素非常简单，就是把一串用空格分割的非空格ASCII字符序列（被称为word）组织在一起，这一点深受Lisp的影响。每个word既可直接由汇编代码定义，也可由其他word定义。这些word被存在一个叫做字典（不同于其它语言中的数据结构）的结构里，执行也可以以interpret和compile两种方式，其中interpret直接解析字符序列，而compile则是把word所对应在字典中的入口地址汇编成新的序列。而执行的过程即在这些地址之间不断跳转，在JonesForth和当前的Exor中，这个跳转只用到两个寄存器，一个模拟指令指针的功能，通过入口地址进入到word所对应的实际可执行的代码，另一个则暂存当执行完这个word后将要跳转到的下一个入口地址。

 从这个描述我们大概可以看出Forth有几个特点。首先这样的思路使它不会用到call/ret指令，跳转过程完全用unconditional jump来完成。在频繁的函数调用中，这会缩减代码尺寸，并且减少压栈出栈工作。其次我们能观察到，上面提到的两个寄存器的工作方式和函数调用所用到的stack pointer/frame pointer很类似，但是这种跳转是不包含函数调用上下文的，唯一要保存的便是下一个入口地址。这样使得forth需要的内核空间非常少。

 这个特性当然会带来一些tradeoff，与C的函数调用相比，它不遵从POSIX的ABI。C的函数调用是非常繁重的工作，有一系列的压栈出栈工作，并且很难在编译器优化的时候去除掉。然而没有这种保存上下文的工作，会使得Forth极为状态依赖。那么Forth是通过两种编程规范来规避状态依赖带来的麻烦的，首先在小尺度的场景下，每个寄存器要分配固定的数值，其次在大尺度的场景下，总是初始化寄存器，然后将大量的数据存储在固定的数据结构中。对于大尺度的场景不鼓励直接使用汇编编写，而是组合用汇编写成的word。

 Forth是一个非常底层的语言，在标准库中甚至没有循环结构，你需要自己实现IF-ELSE或者FOR-LOOP结构。它沿用了这种汇编语言的开发方式，就是它提供了一套infrastructure，你需要在这个基础上再建立自己的东西。Exor也是基于同样的思路，它希望你自己设计工具，以及设计用来设计工具的工具。你甚至可以用Exor现有的工具实现一个更为优化的Exor编译器，或是生成一个更精巧的Exor系统。

3. **一些哲学**
 我个人其实比较反对将计算机系统区分为操作系统和应用程序的做法，因为对CPU而言并不对此加以区分。我也不认同将涉及计算机的人分为开发者和使用者两种身份，我觉得任何一个使用计算机的人都应当为实现自己的目的设计合适的工具。这就好比将和饭有关的人分为做饭的人和吃饭的人两种身份，我也觉得每个人都应当提高自己的厨艺，自己做饭自己吃。这当中没有什么震撼人心的道理，但是至少如果你愿意花时间亲自做一些事情，你的人生会充实很多，而且它会为你带来自由和快乐，但如果把这些都留给别人，你的人生会到处都是限制。

 Exor就是这样一个系统，它很简单，很容易出错，会很不好用，要使它变得好用需要使用者花不少时间。它要暴露计算机本质的复杂，因为计算机本身就很复杂。它不帮你来对付这种复杂，但它是你自己用来对付这种复杂的工具。而且比起人生来说它并不算复杂。
