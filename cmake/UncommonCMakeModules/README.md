# UncommonCMakeModules

An assortment of modern CMake Modules and building blocks to automate CMake boiler-plate tasks, making boring things easier to avoid messing up.   This library has a focus on scientific computing applications, but many general purpose tools also.

## Using UncommonCMakeModules

The easiest way to use one or more of the CMake modules is to use the [git subrepo](https://github.com/ingydotnet/git-subrepo) plugin.  Unlike the traditional `git submodule` command, `git subrepo` is transparent to other users of your repository, and solves many of the irksome issues prevalent with the submodule approach.  Follow the [git subrepo install guide](https://github.com/ingydotnet/git-subrepo#installation-instructions) to install on your development machine.

Then to use UncommonCMakeModules,
```
> cd $MY_REPOS
> git subrepo clone https://github.com/markjolah/UncommonCMakeModules cmake/UncommonCMakeModules
```
In `CMakeLists.txt`:

```.cmake
 list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCMakeModules)
```

To prevent github's [linguist](https://github.com/github/linguist) script from autodetecting all this CMake code:
```.sh
echo "cmake/UncommonCMakeModules/* linguist-vendored" >> .gitattributes
```

### Compatibility

These modules were designed to be used from Linux to build naively and cross-compile to other Linux, OSX, and Windows 64-bit targets.  They are generally unlikely to work without modification for Win64 VS CMake builds.

## Modules summary

 * [`AddExternalDependency`](AddExternalDependency.cmake) and [`AddExternalAutotoolsDependency`](AddExternalAutotoolsDependency.cmake) - Allow a CMake- or autotools-based dependency to be automatically added as a CMake ExternalProject.  If not present on the system, the dependency package is automatically cloned, configured, and  built, and it is installed to CMAKE_INSTALL_PREFIX.  All this happens *before configure time* for the client package, so that the dependency will be automatically found through the installed CMake package configuration files using the normal `find_package()` mechanism.
 * [`ExportPackageWizzard`](ExportPackageWizzard.cmake) - Automate preparation of [CMake packaging](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html) using PackageConfig files so that the CMake package can be found correctly with `find_package()` both from both the install- and build-trees.
 * [`FixupDependencies`](FixupDependencies.cmake) - This tool automatically works to find and copy necessary dependencies to the build or install tree to allow packaging of cross-compiled packages together with their runtime dependencies.
 * [`MakePkgConfigTarget`](MakePkgConfigTarget.cmake) - Enables use of `pkg-config` to find installed packages using `package-name.pc` files. Unlike built-in `FindPkgConfig.cmake`, this module is cross-compiling aware and creates modern CMake imported interface targets with proper namespaces.
 * [`SmarterPackageVersionFile`](SmarterPackageVersionFile.cmake) - A [PackageConfigVersion.cmake](https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#package-version-file) file generator that is aware of build types and provided components.  Enables a search of multiple build directories in the CMake user repository, each with different incompatible provided component options or build-types (e.g., Debug, Release, etc.).  Only a matching package with the right build-type and required components will satisfy the normal package-version check.

## Find Modules
CMake has evolved rapidly since many of the provided CMake find modules (`FindXXX.cmake`) were written.  Old style CMake find modules return `PkgName_LIBRARIES` and `PkgName_INCLUDE` variables and similar names in a somewhat disorganized and un-standardized way.  This style of find module adds a lot of complexity to the process of linking the dependency.

Modern CMake find modules address this deficiency with *imported interface targets*:
```.cmake
add_library(Foo::Foo IMPORTED INTERFACE)
```
Then all the include directories, compile definitions, compile options, compile features, as well as linked libraries, and their respective PUBLIC and INTERFACE property variants are all automatically set with easy to use and hard to misuse commands:

```.cmake
find_package(Foo REQUIRED)
target_link_libraries(MyTarget PUBLIC Foo::Foo)
```
Each of the UncommonCMakeModule find modules creates a namespace matching the `<PackageName>` argument given to `find_package()`.  The main library has the same name as the namespace (e.g., `Foo::Foo`).  Individual find modules also create other useful namespaced-targets as documented in each file (e.g., `Foo::FooThreads`. `Foo::FooStatic`, etc.).

Unless otherwise noted the find modules are dependency-free and can be copied individually for projects that require only a few of these find modules and don't want a full UncommonCMakeModules subrepo install.

 * [`FindArmadillo`](FindArmadillo.cmake) - Provides `Armadillo::Armadillo` and `COMPONENTS` integration with BLAS and LAPACK.
 * [`FindBLAS`](FindBLAS.cmake) - Provides `BLAS::Blas` and myriad targets for BLAS and CBLAS libraries with and without threading and 64-bit integer support.  Depends on `MakePkgConfigTarget.cmake`.
 * [`FindLAPACK`](FindLAPACK.cmake) - Provides `LAPACK::Lapack` and corresponding targets for LAPACK and LAPACKE corresponding to the BLAS CBLAS packages in `FindBLAS.cmake`].  Depends on `MakePkgConfigTarget.cmake`.
  * [`FindGPerfTools`](FindGPerfTools.cmake) - Provides `GPerfTools::profiler`, a target to integrate with the Google [gperftools](https://github.com/gperftools/gperftools).
  * [`FindLibCXX`](FindLibCXX.cmake) - Provides: `LibCXX::LibCXX`.  The [libc++ library](https://libcxx.llvm.org/) is the `libstdc++.so` replacement from the folks at LLVM.
  * [`FindPThread`](FindPThread.cmake) - Provides `Pthread::Pthread` with cross-platform aware Pthreads detection for GCC and mingw-w64.
  * [`FindTRNG`](FindTRNG.cmake) - Provides `TRNG::TRNG` target for the [TRNG parallel random number generator library](https://www.numbercrunch.de/trng/).

## Toolchains

## Toolchains for Matlab Target Environments

The toolchains in the `Toolchains` sub-directory are mainly intended for cross-compiling to a Matlab target environments.  Targing a particular matlab release
requires the correct GCC version.
* [Matlab and MEX Linking](https://markjolah.github.io/MexIFace/md__home_travis_build_markjolah_MexIFace_doc_text_matlab-mex-linking.html) - Details on building and linking for a particlar Matlab target envornment.

#### gcc-4.9.4 development environment for Matlab `glnxa64` R2016b+ targets
* [`Toolchain-x86_64-gcc4_9-linux-gnu`](Toolchains/Toolchain-x86_64-gcc4_9-linux-gnu.cmake) - gcc-4.9.4 is compatible with Matlab targets R2016b+.
* Environment variable settings:
    * `X86_64_GCC4_9_LINUX_GNU_ROOT` - path to root of gcc-4.9.4 target system

#### gcc-6.5.0 development environment for Matlab `glnxa64` R2018a+ targets
* [`Toolchain-x86_64-gcc6_5-linux-gnu`](Toolchains/Toolchain-x86_64-gcc6_5-linux-gnu.cmake) - gcc-6.5.0 is compatible with Matlab targets R2018a+.
* Environment variable settings:
    * `X86_64_GCC6_5_LINUX_GNU_ROOT` - path to root of gcc-6.5.0 target system

#### mingw-w64/gcc-4.9.4 development environment for Matlab `win64` R2016b+ targets
* [[`Toolchain-MXE-x86_64-w64-mingw32`](Toolchains/Toolchain-MXE-x86_64-w64-mingw32.cmake) - Build for a Win64 target arch with a GCC 4.9.x environment.
* [MXE-MexIFace](https://github.com/markjolah/MXE-MexIFace) - A `mingw-w64` based cross-compiling environment for Matlab Win64 targets.
    * A tracking fork of [MXE](http://mxe.cc) focusing on numerical code and BLAS/LAPACK compatibility with Matlab.
    * Run `make` in repository root to cross-compile all required dependencies for Matlab win64 targets.
* Environment variable settings:
    * `MXE_ROOT` - path to root of local MXE-MexIFace git repo.

## About the name
It seemed like "CommonCMakeModules" would have already been taken.

Hopefully individual Modules developed in this subrepo will find their own homes once they become more robustly tested in different build environments.

# License
 * Author: Mark J. Olah
 * Email: (mjo@cs.unm DOT edu)
 * Copyright: 2019
 * LICENSE: Apache 2.0.  See [LICENSE](https://github.com/markjolah/UncommonCMakeModules/blob/master/LICENSE) file.
