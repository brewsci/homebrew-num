class BrewsciArpack < Formula
  desc "Routines to solve large scale eigenvalue problems"
  homepage "https://github.com/opencollab/arpack-ng"
  url "https://github.com/opencollab/arpack-ng/archive/3.6.3.tar.gz"
  sha256 "64f3551e5a2f8497399d82af3076b6a33bf1bc95fc46bbcabe66442db366f453"
  revision 1
  head "https://github.com/opencollab/arpack-ng.git"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    sha256 "5e39eb27a3e0f53fcf315f92069a72dd80d42317ef82180453a4a4e1d078ec51" => :sierra
    sha256 "2c2dc374167e6687dc28c5d16974508c8312e430d5b698c0f963e01efc3756cb" => :x86_64_linux
  end

  keg_only "arpack is provided by homebrew/core"

  option "with-mpi", "build with MPI"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  depends_on "gcc"
  depends_on "open-mpi" if build.with? "mpi"
  depends_on "openblas"

  def install
    args = %W[ --disable-dependency-tracking
               --prefix=#{libexec}
               --with-blas=-L#{Formula["openblas"].opt_lib}\ -lopenblas]

    args << "F77=#{ENV["MPIF77"]}" << "--enable-mpi" if build.with? "mpi"

    system "./bootstrap"
    system "./configure", *args
    system "make"
    system "make", "install"

    lib.install_symlink Dir["#{libexec}/lib/*"].select { |f| File.file?(f) }
    (lib/"pkgconfig").install_symlink Dir["#{libexec}/lib/pkgconfig/*"]
    pkgshare.install "TESTS/testA.mtx", "TESTS/dnsimp.f",
                     "TESTS/mmio.f", "TESTS/debug.h"

    if build.with? "mpi"
      (libexec/"bin").install (buildpath/"PARPACK/EXAMPLES/MPI").children
    end
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
