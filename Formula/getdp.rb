class Getdp < Formula
  desc "Open source finite element solver using mixed elements"
  homepage "https://www.geuz.org/getdp/"
  url "https://getdp.info/src/getdp-3.3.0-source.tgz"
  sha256 "eebef98fdef589e83a29d92599dfdd373d29fda6fbb31298f1e523be848fdbdd"
  license "GPL-2.0-or-later"

  bottle :disable, "needs to be rebuilt with latest open-mpi"

  depends_on "cmake" => :build
  depends_on "arpack"
  depends_on "gmsh"
  depends_on "open-mpi"
  depends_on "petsc-complex"

  def install
    args = std_cmake_args
    args << "-DENABLE_BUILD_SHARED=ON"
    args << "-DENABLE_SLEPC=OFF"
    args << "-DENABLE_MPI=ON"

    ENV["PETSC_DIR"] = Formula["petsc-complex"].opt_prefix
    ENV["PETSC_ARCH"] = "complex"

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
      system "make", "test" if build.with? "check"
    end
  end

  test do
    system "#{bin}/getdp", "#{share}/doc/getdp/demos/magnet.pro"
  end
end
