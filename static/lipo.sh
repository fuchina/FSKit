#lipo -create /Users/dongdongfu/Documents/GitHub/Private/FSKit/static/a/FSKit /Users/dongdongfu/Documents/GitHub/Private/FSKit/static/b/FSKit -output /Users/dongdongfu/Documents/GitHub/Private/FSKit/static/c/FSKit.a

lipo -create a/FSKit b/FSKit -output c/FSKit.a

# 2023.07.30 应用，需要创建c目录
