##使用方法：
* 直接在setup.sh中修改cwd变量为依赖环境工作目录，如：cwd=env/
* 运行 ./setup.sh 获取依赖环境
* 直接在run.sh中修改cwd变量为拓扑测量工作目录，如：cwd=target/
* 在run.sh中修改target_ip_list变量，改为想要的存储目标ip列表文件的名称，如：target_ip_list="ip_list_cn"
* 在run.sh中修改trace_ip_file变量，改为想要的存储traceroute中所有ip接口地址的文件名称，如：trace_ip_file="trace_ip_list"
* 在run.sh中修改node_name变量，改为想要的本主机id，如：node_name="hit.12"
* 运行 ./run.sh 开始进行拓扑测量和接口合并

##说明：
* 目标ip列表来源是routeview项目提供的bgpsnapshot和五大RIR提供的delegation file综合得到的。方法是从delegation file中获得国家号为CN的AS号列表，然后再从BGPsnapshot中获得所有CN的网段，最后将网段拆分成c类网，每个网随机取一个地址。
* BGP snapshot的解析使用ripencc维护的libbgpdump工具，使用bash的管道进行数据输入。
* 测量工具使用CAIDA组织提供的scamper工具，scamper提供了traceroute和接口合并工具ally的实现。
