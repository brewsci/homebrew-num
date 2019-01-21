class BrewsciQrupdate < Formula
  desc "Fast updates of QR and Cholesky decompositions"
  homepage "https://sourceforge.net/projects/qrupdate/"
  url "https://downloads.sourceforge.net/qrupdate/qrupdate-1.1.2.tar.gz"
  sha256 "e2a1c711dc8ebc418e21195833814cb2f84b878b90a2774365f0166402308e08"
  revision 1

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "1af31078e954a20e69baf0e3e312eb7a1bb1f8ab426aeb4a2a1b3cb982254bbc" => :sierra
    sha256 "078de0cdca0ff1bca81692c263f5e48e837335853e1c2e174c7c82e7fa1733f2" => :x86_64_linux
  end

  keg_only "qrupdate is provided by homebrew/core"

  depends_on "gcc"
  depends_on "openblas"

  def install
    # Parallel compilation not supported. Reported on 2017-07-21 at
    # https://sourceforge.net/p/qrupdate/discussion/905477/thread/d8f9c7e5/
    ENV.deparallelize

    system "make", "lib", "solib", "FC=gfortran",
                   "BLAS=-L#{Formula["openblas"].opt_lib} -lopenblas"

    # Confuses "make install" on case-insensitive filesystems
    rm "INSTALL"

    # BSD "install" does not understand GNU -D flag.
    # Create the parent directory ourselves.
    inreplace "src/Makefile", "install -D", "install"
    lib.mkpath

    system "make", "install", "PREFIX=#{prefix}"
    pkgshare.install "test/tch1dn.f", "test/utils.f"
  end

  test do
    ENV.prepend_path "LD_LIBRARY_PATH", lib unless OS.mac?
    system "gfortran", "-o", "test", pkgshare/"tch1dn.f", pkgshare/"utils.f",
                   "-L#{lib}", "-lqrupdate", "-L#{Formula["openblas"].opt_lib}", "-lopenblas"
    assert_match "PASSED   4     FAILED   0", shell_output("./test")
  end
end
