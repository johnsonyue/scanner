##使用方法：
* 添加lib目录
    * 在/etc/ld.so.conf文件中添加如下行：include /usr/local/lib，之后在终端输入如下命令：ldconfig
* 修改config.ini文件
    * env_dir变量为依赖环境工作目录，如：env_dir=env/
    * cwd变量为拓扑测量工作目录，如：cwd=target/
    * target_ip_list变量改为想要的存储目标ip列表文件的名称，如：target_ip_list=ip_list_cn
    * trace_ip_file变量改为想要的存储traceroute中所有ip接口地址的文件名称，如：trace_ip_file=trace_ip_list
    * node_name变量改为想要的本主机id，如：node_name=hit.12
    * iffinder_path变量代表iffinder可执行程序的路径
    * midar_path变量代表midar可执行程序的路径
    * interface变量改为本机对外通信的网卡名称
    * mper_port变量代表mper daemon程序运行占用的端口
    * iffinder_path, midar_path,mper_port通常不需要修改，默认值即可
* 第一次使用需要运行 ./setup.sh 获取依赖环境，或者运行./setup_offline使用env_files.tar.gz压缩包提供的环境进行离线安装
* 如果使用./setup.sh进行在线安装，需要注释吊midar-0.6.0/midar/lib 文件夹下的infile.cc文件中的if ... throw Mismatch两行。
* 运行 ./run.sh 开始进行拓扑测量和接口合并

##说明：
* 目标ip列表来源是routeview项目提供的bgpsnapshot和五大RIR提供的delegation file综合得到的。方法是从delegation file中获得国家号为CN的AS号列表，然后再从BGPsnapshot中获得所有CN的网段，最后将网段拆分成c类网，每个网随机取一个地址。
* BGP snapshot的解析使用ripencc维护的libbgpdump工具，使用bash的管道进行数据输入。
* 测量工具使用CAIDA组织提供的scamper工具，接口合并工具使用CAIDA组织使用的iffinder和MIDAR工具。
