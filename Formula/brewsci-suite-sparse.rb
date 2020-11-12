class BrewsciSuiteSparse < Formula
  desc "Suite of Sparse Matrix Software"
  homepage "http://faculty.cse.tamu.edu/davis/suitesparse.html"
  url "http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-4.5.5.tar.gz"
  sha256 "b9a98de0ddafe7659adffad8a58ca3911c1afa8b509355e7aa58b02feb35d9b6"
  revision 2

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "571a5614ebbf39e1985025a4b189fb0e8d322e44658bdcea5381955941c6add5" => :catalina
    sha256 "e3ca73c5a4d51d88ff85acbd50da0242dd4125dbaa3ac37d3472536f8ef9312d" => :x86_64_linux
  end

  keg_only "suite-sparse is provided by homebrew/core"

  depends_on "brewsci/num/brewsci-metis"
  depends_on "openblas"

  def install
    args = [
      "INSTALL=#{prefix}",
      "BLAS=-L#{Formula["openblas"].opt_lib} -lopenblas",
      "LAPACK=$(BLAS)",
      "MY_METIS_LIB=-L#{Formula["brewsci-metis"].opt_lib} -lmetis",
      "MY_METIS_INC=#{Formula["brewsci-metis"].opt_include}",
    ]
    system "make", "library", *args
    system "make", "install", *args
    lib.install Dir["**/*.a"]
    pkgshare.install "KLU/Demo/klu_simple.c"
  end

  test do
    ENV.prepend_path "LD_LIBRARY_PATH", lib unless OS.mac?
    system ENV.cc, "-o", "test", "-I#{include}", pkgshare/"klu_simple.c",
                   "-L#{lib}", "-lsuitesparseconfig", "-lklu"
    system "./test"
  end
end
