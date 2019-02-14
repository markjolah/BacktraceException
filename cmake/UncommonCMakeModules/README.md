# UncommonCMakeModules

An assortment of modern CMake Modules to help automate some CMake boiler-plate tasks that small and medium projects often spend too much time and effort in getting correct, or just don't get correct at all.  This library has a focus on scientific computing applications, but many general purpose tools also.

Copyright: 2013-2019
Author: Mark J. Olah
Email: (mjo@cs.unm DOT edu)
LICENSE: APACHE 2.0, see: [LICENSE](LICENSE)

## Using UncommonCMakeModules

The easiest way to use one or more of the modules provided is to use the [git subrepo](https://github.com/ingydotnet/git-subrepo) plugin.  Unlike the traditional `git submodule` command, `git subrepo` is transparent to other users of your repository, and solves many of the irksome issues prevalent with the submodule approach.  Follow the [git subrepo install guide](https://github.com/ingydotnet/git-subrepo#installation-instructions) to install on your development machine.

Then to use UncommonCMakeModules,
```
> cd $MY_REPOS
> git subrepo pull https://github.com/markjolah/UncommonCMakeModules cmake/UncommonCMakeModules
```
In `CMakeLists.txt`:

```
 list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCMakeModules)
```

To prevent github's [linguist](https://github.com/github/linguist) script from autodetecting all this CMake code:
```
> echo "cmake/UncommonCMakeModules/* linguist-vendored" >> .gitattributes
```

### Compatibility

These modules were designed to be used from Linux to build naively and cross-compile to Linux, OSX, and Windows 64-bit.

## Modules summary

 * [`AddExternalDependency`](AddExternalDependency.cmake) and [`AddExternalAutotoolsDependency`](AddExternalAutotoolsDependency.cmake) - These modules allows a CMake-based or autotools-based dependency to be automatically added as a CMake ExternalProject.  The package is automatically cloned, built, and installed to CMAKE_INSTALL_PREFIX.  All this happens *before configure time* for the client package, so that the dependency will be automatically found through the cmake `<PackageName>Config.cmake` files and the normal `find_package()` mechanism.
 * [`ExportPackageWizzard`](ExportPackageWizzard.cmake) - Automate preparation of CMake package-config and target export files so that this package can be found correctly with `find_package()` both from both the install tree and the build tree.
 * [`FixupDependencies`](FixupDependencies.cmake) - This tool automatically works to find and copy necessary dependencies to the build or install tree to allow packaging of cross-compiled packages together with their runtime dependencies.
 * [`MakePkgConfigTarget`](MakePkgConfigTarget.cmake) - Enables use of `pkg-config` to find packages that produce `pagage-name.pc` files, and with cross-compiling awareness automatically creates modern CMake namespaced and imported-targets.
 * [`SmarterPackageVersionFile`](SmarterPackageVersionFile.cmake) - A PackageVersion.cmake file generator that is aware of build types and provided components.  Enables a search of multiple build directories in the CMake user repository, each with different incompatible provided component options or build-types (e.g., Debug, Release, etc.).  Only a matching package with the right build-type and required components will satisfy the normal package-version check.

## Find Modules
CMake has evolved rapidly since many of the provided CMake find modules (`FindXXX.cmake`) were written.  Old style CMake find modules returned `PkgName_LIBRARIES` and `PkgName_INCLUDE` variables and simillar names in a somewhat disorganized and un-standardized way.  This style of find module adds a lot of complexity to the process of linking the dependency.

Modern CMake find modules address this deficiency with *imported interface targets*: `add_library(Foo::Foo IMPORTED INTERFACE)`. Then all the include directories, compile definitions, compile options, compile features, as well as linked libraries, and their respective PUBLIC and INTERFACE properties are all automatically set:
```
find_package(Foo REQUIRED)
target_link_librearies(MyTarget PUBLIC Foo::Foo)
```
Each of the UncommonCMakeModule find modules creates a namespace matchinthe `<PackageName>` argument given to `find_package()`.  The main library has the same name as the namespace (e.g., `Foo::Foo`).  Individual find modules also create other useful namespaced-targets as documented in each file (e.g., `Foo::FooTreads`. `Foo::FooStatic`, etc.).

Unless otherwise noted the find modules are dependency-free and can be copied individually for projects that require only a few of these Find modules and don't want a full UncommonCMakeModules subrepo install.

 * [`FindArmadillo`](FindArmadillo.cmake) - Provides `Armadillo::Armadillo` and `COMPOENTS` integration with BLAS and LAPACK.
 * [`FindBLAS`](FindBLAS.cmake) - Provides `BLAS::Blas` and myriad targets for BLAS and CBLAS libraries with and without threading and 64-bit integer support.  Depends on `MakePkgConfigTarget.cmake`.
 * [`FindLAPACK`](FindLAPACK.cmake) - Provides `LAPACK::Lapack` and corresponding targets for LAPACK and LAPACKE corresponding to the BLAS CBLAS packages in `FindBLAS.cmake`].  Depends on `MakePkgConfigTarget.cmake`.
  * [`FindGPerfTools`](FindGPerfTools.cmake) - Provides `GPerfTools::profiler`, a target to integrate with the Google [gperftools](https://github.com/gperftools/gperftools).
  * [`FindLibCXX`](FindLibCXX.cmake) - Provides: `LibCXX::LibCXX`.  The [libc++ library](https://libcxx.llvm.org/) is the `libstdc++.so` replacement from the folks at LLVM.
  * [`FindPThread`](FindPThread.cmake) - Provides `Pthread::Pthread` with cross-platform aware Pthreads detection for GCC and mingw64.
  * [`FindTRNG`](FindTRNG.cmake) - Provides `TRNG::TRNG` for the [TRNG parallel random number generator library](https://www.numbercrunch.de/trng/).
## Toolchains

The toolchains in `Toolchains` sub-directory are mainly intended for use in cross-compiling to a Matlab compatible target arch and GCC version.

 * [`Toolchain-x86_64-gcc4_9-linux-gnu`](Toolchains/Toolchain-x86_64-gcc4_9-linux-gnu.cmake)  - Build in a GCC 4.9.x environment.  Required for Matlab R2013b and newer.
    ```
    export X86_64_GCC4_9_LINUX_GNU_ROOT=/path/to/x86_64-gcc4_9-linux-gnu
    ```
 * [`Toolchain-x86_64-gcc6_5-linux-gnu`](Toolchains/Toolchain-x86_64-gcc6_5-linux-gnu.cmake) - Build in a GCC 4.9.x environment.  Required for Matlab R2013b and newer.
    ```
    export X86_64_GCC6_5_LINUX_GNU_ROOT=/path/to/x86_64-gcc6_5-linux-gnu
    ```
 * [`Toolchain-MXE-x86_64-w64-mingw32`](Toolchains/Toolchain-MXE-x86_64-w64-mingw32.cmake) - Build for a Win64 target arch with a GCC 4.9.x environment using MXE  Required for Matlab R2013b and newer for Win64 targets.
    ```
    export MXE_ROOT=/path/to/mxe
    ```
