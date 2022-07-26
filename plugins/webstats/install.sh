#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


## https://www.yangshuaibin.com/detail/392251

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

install_tmp=${rootPath}/tmp/mw_install.pl
VERSION=$2
sys_os=`uname`

if [ "$sys_os" == "Darwin" ];then
	BAK='_bak'
else
	BAK=''
fi

Install_App()
{
	echo '正在安装脚本文件...' > $install_tmp
	mkdir -p $serverPath/source/webstats


	mkdir -p $serverPath/webstats

	# 下载源码安装包
	# curl -O $serverPath/source/webstats/lua-5.1.5.tar.gz https://www.lua.org/ftp/lua-5.1.5.tar.gz
	# cd $serverPath/source/webstats && tar xvf lua-5.1.5.tar.gz
	# cd lua-5.1.5
	# make linux test && make install

	
	# luarocks
	if [ ! -f $serverPath/source/webstats/luarocks-3.5.0.tar.gz ];then
		wget --no-check-certificate -O $serverPath/source/webstats/luarocks-3.5.0.tar.gz http://luarocks.org/releases/luarocks-3.5.0.tar.gz
	fi
	
	# which luarocks
	# if [ "$?" != "0" ];then
	if [ ! -d $serverPath/webstats/luarocks ];then
		cd $serverPath/source/webstats && tar xvf luarocks-3.5.0.tar.gz
		# cd luarocks-3.9.1 && ./configure && make bootstrap

		cd luarocks-3.5.0 && ./configure --prefix=$serverPath/webstats/luarocks --with-lua-include=$serverPath/openresty/luajit/include/luajit-2.1 --with-lua-bin=$serverPath/openresty/luajit/bin
		make -I${serverPath}/openresty/luajit/bin
		make install 
	fi


	if [ ! -f  $serverPath/source/webstats/lsqlite3_fsl09y.zip ];then
		wget --no-check-certificate -O $serverPath/source/webstats/lsqlite3_fsl09y.zip http://lua.sqlite.org/index.cgi/zip/lsqlite3_fsl09y.zip?uuid=fsl_9y
		cd $serverPath/source/webstats && unzip lsqlite3_fsl09y.zip
	fi

	PATH=${serverPath}/openresty/luajit:${serverPath}/openresty/luajit/include/luajit-2.1:$PATH
	export PATH=$PATH:$serverPath/webstats/luarocks/bin

	if [ "${sys_os}" == "Darwin" ];then
		cd $serverPath/source/webstats/lsqlite3_fsl09y 
		# SQLITE_DIR=/usr/local/Cellar/sqlite/3.36.0
		find_cfg=`cat Makefile | grep 'SQLITE_DIR'`
		if [ "$find_cfg" == "" ];then
			LIB_SQLITE_DIR=`brew info sqlite | grep /usr/local/Cellar/sqlite | cut -d \  -f 1 | awk 'END {print}'`
			sed -i $BAK "s#\$(ROCKSPEC)#\$(ROCKSPEC) SQLITE_DIR=${LIB_SQLITE_DIR}#g"  Makefile
		fi
		make
	else
		cd $serverPath/source/webstats/lsqlite3_fsl09y && make
	fi

	# copy to code path
	DEFAULT_DIR=$serverPath/webstats/luarocks/lib/lua/5.1
	if [ -f ${DEFAULT_DIR}/lsqlite3.so ];then
		mkdir -p $serverPath/webstats/lua
		cp -rf ${DEFAULT_DIR}/lsqlite3.so $serverPath/webstats/lua/lsqlite3.so 
	fi


	if [ ! -f $serverPath/webstats/GeoLite2-City.mmdb ];then
		pip install geoip2
		wget --no-check-certificate -O $serverPath/webstats/GeoLite2-City.mmdb https://git.io/GeoLite2-City.mmdb
	fi

	# GeoLite2-Country.mmdb

	echo "${VERSION}" > $serverPath/webstats/version.pl
	echo '安装完成' > $install_tmp

	if [ "$sys_os" != "Darwin" ];then
		cd $rootPath && python3 ${rootPath}/plugins/webstats/index.py start
	fi
}

Uninstall_App()
{
	rm -rf $serverPath/webstats
	echo "Uninstall_redis" > $install_tmp
}

action=$1
if [ "${1}" == 'install' ];then
	Install_App
else
	Uninstall_App
fi
