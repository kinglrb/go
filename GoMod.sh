# ----------------------------------Go Mod 模式应用
	# go.mod 文件、GO111MODULE 变量、go build -mod 命令及 GOPATH/pkg/mod
		# 决定依赖的版本、依赖包存储位置及参与编译过程的依赖包

# ---------环境变量 GO111MODULE
# go 环境变量 GO111MODULE
	# 3 个值 off、on、auto 
		# 决定是否使用 go mod:
			GO111MODULE=off：	关闭 go modules 功能，	
				编译时，在 $GOPATH/src 或 vendor 目录中寻找依赖
					"GOPATH 模式"包管理
			GO111MODULE=on：	开启 go modules 功能，
				编译时，不会在 $GOPATH/src 中寻找依赖
					在项目根目录生成 go.mod 文件
						依赖包不再存放在 $GOPATH/src 目录，而存放在 $GOPATH/pkg/mod 目录，
							多个项目，可以共享缓存的 modules
			GO111MODULE=auto：	默认值，
				go v1.13，如果工程目录下包含 go.mod 文件，
					或者位于包含 go.mod 文件的目录下，
						则开启 go modules 功能
							go v1.11 中，如设为auto 值，
								需要工程在 GOPATH/src 之外的目录中，才会开启 go mod，确保兼容性

# go mod 命令行
go mod init
	使用 go mod 的工程，其目录下都包含 go.mod 文件
		新工程，若要开启 go mod 管理包依赖，需要创建 go.mod 文件，
			go 1.11 提供 go mod 命令
				初始化 go mod 管理，
					使用 go mod init 命令
						go mod init，可指定工程的 module 名
							处于 GOPATH/src 目录下时，可使用默认值
	GOPATH 目录中
		使用 go mod 的工程，放在 GOPATH/src 目录下，
			可以直接用 go mod init 初始化，
				将自动检测 $GOPATH/src 后的目录，作为包的 module
					# 执行：
					go mod init
	GOPAHT 目录外
		工程在 GOPATH 之外，使用 go mod，
			# mod 初始化时，需要给当前工程指定 moudle 目录，如：
				go mod init github.com/repo/package

# go mod 包管理常用三个命令
	# init、tidy、vendor，
		# 完成 go mod 初始化、依赖文件检查更新、及自动建立 vendor 目录
 # // 常用命令
 go mod init        // 初始化 go.mod，将开启 mod 使用
 go mod tidy        // 添加或者删除 modules，取决于依赖的引用
 go mod vendor      // 复制依赖到 vendor 目录下
 # // 其它命令
 go mod download  // 下载 module 到本地
 go mod edit     //  编辑 go.mod
 go mod graph    //  打印 modules 依赖图
 go mod verify   //  验证依赖
 go mod why      //  解释依赖使用
 
# go.mod 文件解析
	使用 go mod init 进行 go 工程的 mod 初始化后，
		在目录下将生成 go.mod 文件，
			# go.mod记录了当前工程的 module 名，使用的 go 版本，依赖的 go package 及进行过 replace 替换的工程

# go.mod 文件，记录包依赖：
	module github.com/repo/package
	go 1.14
	require (
		github.com/niemeyer/pretty v0.0.0-20200227124842-a10e7caefd8e // indirect
		github.com/satori/go.uuid v1.2.1-0.20181028125025-b2ce2384e17b
		gopkg.in/check.v1 v1.0.0-20200902074654-038fdea0a05b // indirect
	)
replace golang.org/x/crypto v0.0.0-20181203042331-505ab145d0a9 => github.com/golang/crypto v0.0.0-20181203042331-505ab145d0a9

# 一般不需要手动修改 go.mod 文件，
	# 在工程里使用 go get 命令、go mod tidy 命令，都会把依赖自动记录到 go.mod 文件中
go mod tidy 	// 添加工程中使用到的 go 依赖包，并删除未使用过的依赖包.
go get github.com/repo/package@branch 	// 下载指定版本的 go 依赖包

GOPATH 目录下，除了 src 存放工程(依赖) 源代码，还有 bin、pkg 目录，
	bin 目录，存放执行 go install 后的可执行文件，
	pkg 存放依赖包编译的中间文件，
		文件后缀 .a，
			用于工程的编译，
				pkg/ 目录下，首先是平台目录，如 pkg/linux_amd64
					引入 go mod 后，
						GOPATH/pkg/ 目录下，会增加 mod 目录(GOPATH/pkg/mod)，
							存放各版本依赖包的缓存文件，将优先用于代码编译, 
								当 pkg/mod 目录下，不存在指定的依赖包缓存时，
									才会依次去 vendor 目录、GOPATH/src 目录，拷贝指定版本的工程到 pkg/mod 下，再进行编译

# go build -mod 编译模式选择
	# 开启 GO111MODULE=on 后，
		# go build 将使用 mod 模式，寻找依赖包进行编译，
			# GOPATH/src 目录下的依赖将无效
				go build 可携带 -mod 的 flag，
					# 选择不同模式的 mod 编译. 
						# 包括 -mod=vendor、-mod=mod、-mod=readonly
							默认使用 -mod=readonly 模式
								go 1.14，如果目录中出现 vendor 目录，
									# 默认使用 -mod=vendor 模式进行编译。 
						三种 go build 的 flag：
							-mod=readonly
								只读模式，
									# 如果待引入的 package，不在 go.mod 文件的列表中，报错
										不会修改 go.mod，
											# 若模块的 checksum 不在 go.sum 中，也会报错
												只读模式：编译时，可避免隐式修改 go.mod
							-mod=vendor
								mod=vendor 模式下，
									# 将使用工程 vendor 目录下的 package，
										# 而非 mod cache( GOPATH/pkg/mod) 目录
											该模式下编译，不会检查 go.mod 文件下的包版本
												但会检查 vendor 目录下的 modules.txt(由 go mod vendor 生成)
													# go.1.14，若存在 vendor 目录，将优先使用 vendor 模式
							-mod=mod
								mod=vendor 模式下，
									# 将使用 module cache，
										# 即使存在 vendor 目录，
											也会使用 GOPATH/pkg/mod 下的package，
												若 package 不存在，将自动下载指定版本的 package
