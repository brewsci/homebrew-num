class BrewsciCeresSolver < Formula
  desc "C++ library for large-scale optimization"
  homepage "http://ceres-solver.org/"
  url "http://ceres-solver.org/ceres-solver-1.14.0.tar.gz"
  sha256 "4744005fc3b902fed886ea418df70690caa8e2ff6b5a90f3dd88a3d291ef8e8e"
  head "https://ceres-solver.googlesource.com/ceres-solver.git"

  bottle do
    root_url "https://archive.org/download/brewsci/bottles-num"
    sha256 cellar: :any, catalina:     "843571d1820074da8b077dc422637edceba07c690db7bd0e5ef10ad269aaf614"
    sha256 cellar: :any, x86_64_linux: "aea453f8b9b26fc8b9452e53c60974ea97107dae4be11654f177692edaa6adb0"
  end

  keg_only "ceres-solver is provided by homebrew/core"

  unless OS.mac?
    fails_with gcc: "5" do
      cause "Dependency glog is compiled with the GCC 4.8 ABI."
    end
  end

  depends_on "brewsci/num/brewsci-metis"
  depends_on "brewsci/num/brewsci-suite-sparse"
  depends_on "cmake"
  depends_on "eigen"
  depends_on "gflags"
  depends_on "glog"
  depends_on "openblas"

  def install
    so = OS.mac? ? "dylib" : "so"
    system "cmake", ".", *std_cmake_args,
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_LIBRARY_PATH=#{Formula["openblas"].opt_lib}",
                    "-DEIGEN_INCLUDE_DIR=#{Formula["eigen"].opt_include}/eigen3",
                    "-DMETIS_LIBRARY=#{Formula["brewsci-metis"].opt_lib}/libmetis.#{so}"
    system "make"
    system "make", "install"
    rm_r Dir["examples/**/CMakeFiles/"]
    pkgshare.install "examples", "data"
    doc.install "docs/html" unless build.head?
  end

  test do
    ENV.prepend_path "LD_LIBRARY_PATH", lib unless OS.mac?

    cp pkgshare/"examples/helloworld.cc", testpath
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 2.8)
      project(helloworld)
      find_package(Ceres REQUIRED PATHS #{Formula["brewsci-ceres-solver"].opt_prefix})
      include_directories(${CERES_INCLUDE_DIRS})
      add_executable(helloworld helloworld.cc)
      target_link_libraries(helloworld ${CERES_LIBRARIES})
    EOS

    system "cmake", "-DCeres_DIR=#{share}/Ceres", "."
    system "make"
    assert_match "CONVERGENCE", shell_output("./helloworld")
  end
end
