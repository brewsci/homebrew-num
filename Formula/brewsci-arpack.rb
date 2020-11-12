class BrewsciArpack < Formula
  desc "Routines to solve large scale eigenvalue problems"
  homepage "https://github.com/opencollab/arpack-ng"
  url "https://github.com/opencollab/arpack-ng/archive/3.7.0.tar.gz"
  sha256 "972e3fc3cd0b9d6b5a737c9bf6fd07515c0d6549319d4ffb06970e64fa3cc2d6"
  head "https://github.com/opencollab/arpack-ng.git"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "5dcb61920e5aa67dc0e69aedb46fbda4f6fda2e11297e316c47dea30bafbfeda" => :sierra
    sha256 "463206ba3efec251843c8b5356e4bc14442fd6bdc8baf655546facd791936fbf" => :x86_64_linux
  end

  keg_only "arpack is provided by homebrew/core"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build

  depends_on "gcc"
  depends_on "openblas"
  depends_on "open-mpi" => :optional

  def install
    args = %W[ --disable-dependency-tracking
               --prefix=#{libexec}
               --with-blas=-L#{Formula["openblas"].opt_lib}\ -lopenblas]

    args << "F77=#{ENV["MPIF77"]}" << "--enable-mpi" if build.with? "open-mpi"

    system "./bootstrap"
    system "./configure", *args
    system "make"
    system "make", "install"

    lib.install_symlink Dir["#{libexec}/lib/*"].select { |f| File.file?(f) }
    (lib/"pkgconfig").install_symlink Dir["#{libexec}/lib/pkgconfig/*"]
    pkgshare.install "TESTS/testA.mtx", "TESTS/dnsimp.f",
                     "TESTS/mmio.f", "TESTS/debug.h"

    (libexec/"bin").install (buildpath/"PARPACK/EXAMPLES/MPI").children if build.with? "open-mpi"
  end

  test do
    ENV.fortran
    args = %W[-L#{opt_lib} -larpack -L#{Formula["openblas"].opt_lib} -lopenblas]
    args << "-Wl,-rpath=#{lib}" if OS.linux?
    system ENV.fc, "-o", "test", pkgshare/"dnsimp.f", pkgshare/"mmio.f", *args
    cp_r pkgshare/"testA.mtx", testpath
    assert_match "reached", shell_output("./test")

    if build.with? "mpi"
      cp_r (libexec/"bin").children, testpath
      %w[pcndrv1 pdndrv1 pdndrv3 pdsdrv1
         psndrv1 psndrv3 pssdrv1 pzndrv1].each do |slv|
        system "mpirun", "-np", "4", slv
      end
    end
  end
end
