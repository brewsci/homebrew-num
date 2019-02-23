class BrewsciMumps < Formula
  desc "Parallel Sparse Direct Solver"
  homepage "http://mumps-solver.org"
  url "http://mumps.enseeiht.fr/MUMPS_5.1.2.tar.gz"
  sha256 "eb345cda145da9aea01b851d17e54e7eef08e16bfa148100ac1f7f046cd42ae9"
  revision 2

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "299c4495de3e9dff186d763c4fb971cc1e059e5a6105b20538e39a14c08b4f06" => :sierra
    sha256 "32f29592a61ebf9aae4d1f4556063d8263383e129260b8064815168f4ad9830f" => :x86_64_linux
  end

  keg_only "formulae in brewsci/num are keg only"

  option "without-mpi", "build without MPI"

  depends_on "brewsci/num/brewsci-scalapack" if build.with? "mpi"
  depends_on "gcc"
  depends_on "open-mpi" if build.with? "mpi"
  depends_on "openblas"

  depends_on "brewsci/num/brewsci-metis" => :recommended if build.without? "mpi"
  depends_on "brewsci/num/brewsci-parmetis" => :recommended if build.with? "mpi"
  depends_on "brewsci/num/brewsci-scotch" => :optional
  depends_on "brewsci/num/brewsci-scotch@5" => :optional

  fails_with :clang # because we use OpenMP

  resource "mumps_simple" do
    url "https://github.com/dpo/mumps_simple/archive/v0.4.tar.gz"
    sha256 "87d1fc87eb04cfa1cba0ca0a18f051b348a93b0b2c2e97279b23994664ee437e"
  end

  def install
    make_args = ["RANLIB=echo", "OPTF=-O", "CDEFS=-DAdd_"]
    orderingsf = "-Dpord"

    makefile = build.with?("mpi") ? "Makefile.G95.PAR" : "Makefile.G95.SEQ"
    cp "Make.inc/" + makefile, "Makefile.inc"

    lib_args = []

    if build.with? "brewsci-scotch@5"

      scotch_dir = Formula["brewsci-scotch@5"].opt_prefix
      make_args += ["SCOTCHDIR=#{scotch_dir}", "ISCOTCH=-I#{Formula["brewsci-scotch@5"].opt_include}"]

      if build.with? "mpi"
        scotch_libs = "-L$(SCOTCHDIR)/lib -lptesmumps -lptscotch -lptscotcherr"
        scotch_libs += " -lptscotchparmetis" if build.with? "parmetis"
        orderingsf << " -Dptscotch"
      else
        scotch_libs = "-L$(SCOTCHDIR)/lib -lesmumps -lscotch -lscotcherr"
        scotch_libs += " -lscotchmetis" if build.with? "brewsci-metis"
        orderingsf << " -Dscotch"
      end
      make_args << "LSCOTCH=#{scotch_libs}"
      lib_args += scotch_libs.split

    elsif build.with? "scotch"

      scotch_dir = Formula["brewsci-scotch"].opt_prefix
      make_args += ["SCOTCHDIR=#{scotch_dir}", "ISCOTCH=-I#{Formula["brewsci-scotch"].opt_include}"]

      if build.with? "mpi"
        scotch_libs = "-L$(SCOTCHDIR)/lib -lptscotch -lptscotcherr -lptscotcherrexit -lscotch"
        scotch_libs += "-lptscotchparmetis" if build.with? "brewsci-parmetis"
        orderingsf << " -Dptscotch"
      else
        scotch_libs = "-L$(SCOTCHDIR)/lib -lscotch -lscotcherr -lscotcherrexit"
        scotch_libs += "-lscotchmetis" if build.with? "brewsci-metis"
        orderingsf << " -Dscotch"
      end
      make_args << "LSCOTCH=#{scotch_libs}"
      lib_args += scotch_libs.split

    end

    if build.with? "brewsci-parmetis"
      metis_libs = "-L#{Formula["brewsci-parmetis"].opt_lib} -lparmetis -L#{Formula["brewsci-metis"].opt_lib} -lmetis"
      make_args += ["LMETISDIR=#{Formula["brewsci-parmetis"].opt_lib}",
                    "IMETIS=#{Formula["brewsci-parmetis"].opt_include}",
                    "LMETIS=#{metis_libs}"]
      orderingsf << " -Dparmetis"
      lib_args += metis_libs.split
    elsif build.with? "brewsci-metis"
      metis_libs = "-L#{Formula["brewsci-metis"].opt_lib} -lmetis"
      make_args += ["LMETISDIR=#{Formula["brewsci-metis"].opt_lib}",
                    "IMETIS=#{Formula["brewsci-metis"].opt_include}",
                    "LMETIS=#{metis_libs}"]
      orderingsf << " -Dmetis"
      lib_args += metis_libs.split
    end

    make_args << "ORDERINGSF=#{orderingsf}"

    if build.with? "mpi"
      scalapack_libs = "-L#{Formula["brewsci-scalapack"].opt_lib} -lscalapack"
      make_args += ["CC=mpicc -fPIC",
                    "FC=mpif90 -fPIC",
                    "FL=mpif90 -fPIC",
                    "SCALAP=#{scalapack_libs}",
                    "INCPAR=", # Let MPI compilers fill in the blanks.
                    "LIBPAR=$(SCALAP)"]
      lib_args += scalapack_libs.split
    else
      make_args += ["CC=#{ENV["CC"]} -fPIC",
                    "FC=gfortran -fPIC -fopenmp",
                    "FL=gfortran -fPIC -fopenmp"]
      lib_args << "-lgomp"
    end

    blas_lib = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    make_args << "LIBBLAS=#{blas_lib}"
    lib_args += blas_lib.split

    ENV.deparallelize # Build fails in parallel on Mavericks.

    system "make", "alllib", *make_args

    # make shared lib
    so = OS.mac? ? "dylib" : "so"
    all_load = OS.mac? ? "-all_load" : "--whole-archive"
    noall_load = OS.mac? ? "-noall_load" : "--no-whole-archive"
    compiler = OS.mac? ? "gfortran" : "mpif90" # mpif90 causes segfaults on macOS
    shopts = OS.mac? ? ["-undefined", "dynamic_lookup"] : []
    install_name = ->(libname) { OS.mac? ? ["-Wl,-install_name", "-Wl,#{lib}/#{libname}.#{so}"] : [] }
    cd "lib" do
      libpord_install_name = install_name.call("libpord")
      system compiler, "-fPIC", "-shared", "-Wl,#{all_load}", "libpord.a", *lib_args, \
             "-Wl,#{noall_load}", *libpord_install_name, *shopts, "-o", "libpord.#{so}"
      lib.install "libpord.#{so}"
      libmumps_common_install_name = install_name.call("libmumps_common")
      system compiler, "-fPIC", "-shared", "-Wl,#{all_load}", "libmumps_common.a", *lib_args, \
             "-L#{lib}", "-lpord", "-Wl,#{noall_load}", *libmumps_common_install_name, \
             *shopts, "-o", "libmumps_common.#{so}"
      lib.install "libmumps_common.#{so}"
      %w[libsmumps libdmumps libcmumps libzmumps].each do |l|
        libinstall_name = install_name.call(l)
        system compiler, "-fPIC", "-shared", "-Wl,#{all_load}", "#{l}.a", *lib_args, \
               "-L#{lib}", "-lpord", "-lmumps_common", "-Wl,#{noall_load}", *libinstall_name, \
               *shopts, "-o", "#{l}.#{so}"
      end
    end
    if build.without? "mpi"
      cd "lib/libseq" do
        libmpiseq_install_name = install_name.call("libmpiseq")
        system compiler, "-fPIC", "-shared", "-Wl,#{all_load}", "libmpiseq.a", *lib_args, \
               "-Wl,#{noall_load}", *libmpiseq_install_name, *shopts, "-o", "libmpiseq.#{so}"
      end
    end

    lib.install Dir["lib/*"]
    lib.install "libseq/libmpiseq.#{so}" if build.without? "mpi"

    inreplace "examples/Makefile" do |s|
      s.change_make_var! "libdir", lib
    end

    libexec.install "include"
    include.install_symlink Dir[libexec/"include/*"]
    # The following .h files may conflict with others related to MPI
    # in /usr/local/include. Do not symlink them.
    (libexec/"include").install Dir["libseq/*.h"] if build.without? "mpi"

    doc.install Dir["doc/*.pdf"]
    pkgshare.install "examples"

    prefix.install "Makefile.inc"  # For the record.
    File.open(prefix/"make_args.txt", "w") do |f|
      f.puts(make_args.join(" "))  # Record options passed to make.
    end

    if build.with? "mpi"
      resource("mumps_simple").stage do
        simple_args = ["CC=mpicc", "prefix=#{prefix}", "mumps_prefix=#{prefix}",
                       "scalapack_libdir=#{Formula["brewsci-scalapack"].opt_lib}"]
        if build.with? "brewsci-scotch@5"
          simple_args += ["scotch_libdir=#{Formula["brewsci-scotch@5"].opt_lib}",
                          "scotch_libs=-L$(scotch_libdir) -lptesmumps -lptscotch -lptscotcherr"]
        elsif build.with? "brewsci-scotch"
          simple_args += ["scotch_libdir=#{Formula["brewsci-scotch"].opt_lib}",
                          "scotch_libs=-L$(scotch_libdir) -lptscotch -lptscotcherr -lscotch"]
        end
        simple_args += ["blas_libdir=#{Formula["openblas"].opt_lib}",
                        "blas_libs=-L$(blas_libdir) -lopenblas"]
        system "make", "SHELL=/bin/bash", *simple_args
        lib.install ("libmumps_simple." + (OS.mac? ? "dylib" : "so"))
        include.install "mumps_simple.h"
      end
    end
  end

  def caveats
    s = ""
    if build.without? "mpi"
      s += <<~EOS
        You built a sequential MUMPS library.
        Please add #{libexec}/include to the include path
        when building software that depends on MUMPS.
      EOS
    end
    s
  end

  test do
    ENV.prepend_path "LD_LIBRARY_PATH", lib unless OS.mac?
    cp_r pkgshare/"examples", testpath
    opts = ["-fopenmp"]
    if Tab.for_name("brewsci-mumps").with?("mpi")
      mpiopts = ""
      if OS.linux?
        mpiopts = "--allow-run-as-root" # for CI purposes only
        ENV["OMPI_ALLOW_RUN_AS_ROOT"] = "1"
        ENV["OMPI_ALLOW_RUN_AS_ROOT_CONFIRM"] = "1"
        ENV.prepend_path "LD_LIBRARY_PATH", Formula["brewsci-scalapack"].opt_lib
      end
      f90 = "mpif90"
      cc = "mpicc"
      mpirun = "mpirun -np 1 #{mpiopts}"
      includes = "-I#{opt_include}"
      opts << "-L#{Formula["brewsci-scalapack"].opt_lib}" << "-lscalapack" << "-L#{opt_lib}"
    else
      ENV.prepend_path "LD_LIBRARY_PATH", "#{opt_libexec}/lib" unless OS.mac?
      f90 = "gfortran"
      cc = ENV["CC"]
      mpirun = ""
      includes = "-I#{opt_libexec}/include"
      opts << "-L#{opt_libexec}/lib" << "-lmpiseq"
    end
    if Tab.for_name("brewsci-mumps").with?("brewsci-parmetis")
      ENV.prepend_path "LD_LIBRARY_PATH", Formula["brewsci-parmetis"].opt_lib unless OS.mac?
      opts << "-L#{Formula["brewsci-parmetis"].opt_lib}" << "-lparmetis"
    end
    if Tab.for_name("brewsci-mumps").with?("brewsci-metis")
      ENV.prepend_path "LD_LIBRARY_PATH", Formula["brewsci-metis"].opt_lib unless OS.mac?
      opts << "-L#{Formula["brewsci-metis"].opt_lib}" << "-lmetis"
    end
    opts << "-lmumps_common" << "-lpord"
    opts << "-L#{Formula["openblas"].opt_lib}" << "-lopenblas"

    cd testpath/"examples" do
      system f90, "-o", "ssimpletest", "ssimpletest.F", "-lsmumps", includes, *opts
      system "#{mpirun} ./ssimpletest < input_simpletest_real"
      system f90, "-o", "dsimpletest", "dsimpletest.F", "-ldmumps", includes, *opts
      system "#{mpirun} ./dsimpletest < input_simpletest_real"
      system f90, "-o", "csimpletest", "csimpletest.F", "-lcmumps", includes, *opts
      system "#{mpirun} ./csimpletest < input_simpletest_cmplx"
      system f90, "-o", "zsimpletest", "zsimpletest.F", "-lzmumps", includes, *opts
      system "#{mpirun} ./zsimpletest < input_simpletest_cmplx"
      system cc, "-c", "c_example.c", includes
      system f90, "-o", "c_example", "c_example.o", "-ldmumps", *opts
      system *(mpirun.split + ["./c_example"] + opts)
    end
  end
end
