class BrewsciCeresSolver < Formula
  desc "C++ library for large-scale optimization"
  homepage "http://ceres-solver.org/"
  url "http://ceres-solver.org/ceres-solver-1.13.0.tar.gz"
  sha256 "1df490a197634d3aab0a65687decd362912869c85a61090ff66f073c967a7dcd"
  head "https://ceres-solver.googlesource.com/ceres-solver.git"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "c6aea5ced7a73fb9b37567089e589a31641be7c80aa0c114f9549411eae18727" => :sierra
    sha256 "8572ab626907dc180f4d64e247d57762ed2757b628b3510e842edb9c0d821632" => :x86_64_linux
  end

  keg_only "ceres-solver is provided by homebrew/core"

  unless OS.mac?
    fails_with :gcc => "5" do
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
    pkgshare.install "examples", "data"
    doc.install "docs/html" unless build.head?
  end

  test do
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
