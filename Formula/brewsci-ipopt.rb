class BrewsciIpopt < Formula
  desc "Interior point optimizer"
  homepage "https://github.com/coin-or/Ipopt"
  url "https://github.com/coin-or/Ipopt/archive/releases/3.13.3.tar.gz"
  sha256 "86354b36c691e6cd6b8049218519923ab0ce8a6f0a432c2c0de605191f2d4a1c"
  head "https://github.com/coin-or/Ipopt.git"

  bottle do
    cellar :any
    sha256 "0019198448103a777cf87aee5bee6843756b99ee0f8cbb3d51d2a34c412094ae" => :sierra
    sha256 "d3ab91384dab553137c4da752b559d4b2942f97402b7936401394df6a5e61bf4" => :x86_64_linux
  end

  depends_on "ampl-mp"
  depends_on "brewsci-metis@4"
  depends_on "gcc"
  depends_on "openblas"

  # add MUMPS as a resource so as not to conflict with brewsci-mumps, which is MPI based
  resource "mumps" do
    url "http://mumps.enseeiht.fr/MUMPS_5.2.1.tar.gz"
    sha256 "d988fc34dfc8f5eee0533e361052a972aa69cc39ab193e7f987178d24981744a"
  end

  def install
    ENV.delete("MPICC")
    ENV.delete("MPICXX")
    ENV.delete("MPIFC")

    resource("mumps").stage do
      so = OS.mac? ? "dylib" : "so"
      cp "Make.inc/Makefile.inc.generic.SEQ", "Makefile.inc"
      make_opts = ["LIBEXT=.#{so}",
                   "FC=gfortran",
                   "FL=$(FC)",
                   "OPTF=-fPIC -O",
                   "OPTC=-fPIC -O -I."]
      if OS.mac?
        make_opts << "AR=$(FC) -dynamiclib -undefined dynamic_lookup -Wl,-install_name,#{lib}/$(notdir $@) -o"
        make_opts << "RANLIB=echo"
      end

      ENV.deparallelize { system "make", "d", *make_opts }

      (buildpath/"mumps_include").install Dir["include/*.h", "libseq/mpi.h"]
      lib.install Dir["lib/*.#{so}", "libseq/*.#{so}", "PORD/lib/*.#{so}"]
    end

    args = [
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--enable-shared",
      "--prefix=#{prefix}",
      "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas",
      "--with-metis-incrdir=#{Formula["brewsci-metis@4"].opt_include}",
      "--with-metis-lib=-L#{Formula["brewsci-metis@4"].opt_lib} -lmetis",
      "--with-mumps-incdir=#{buildpath}/mumps_include",
      "--with-mumps-lib=-L#{lib} -ldmumps -lmpiseq -lmumps_common -lopenblas -lpord",
      "--with-asl-incdir=#{Formula["ampl-mp"].opt_include}/asl",
      "--with-asl-lib=-L#{Formula["ampl-mp"].opt_lib} -lasl",
    ]

    system "./configure", *args
    system "make"

    ENV.deparallelize
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <cassert>
      #include <IpIpoptApplication.hpp>
      #include <IpReturnCodes.hpp>
      #include <IpSmartPtr.hpp>
      int main() {
        Ipopt::SmartPtr<Ipopt::IpoptApplication> app = IpoptApplicationFactory();
        const Ipopt::ApplicationReturnStatus status = app->Initialize();
        assert(status == Ipopt::Solve_Succeeded);
        return 0;
      }
    EOS

    system ENV.cxx, "test.cpp", "-I#{include}/coin", "-L#{lib}", "-lipopt"
    system "./a.out"

    # IPOPT still fails to converge on the Waechter-Biegler problem?!?!
    system "#{bin}/ipopt", "#{Formula["ampl-mp"].opt_pkgshare}/example/wb"
  end
end
