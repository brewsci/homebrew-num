class BrewsciMumps < Formula
  desc "Parallel Sparse Direct Solver"
  homepage "http://mumps-solver.org"
  url "http://mumps.enseeiht.fr/MUMPS_5.3.5.tar.gz"
  sha256 "e5d665fdb7043043f0799ae3dbe3b37e5b200d1ab7a6f7b2a4e463fd89507fa4"

  bottle do
    root_url "https://archive.org/download/brewsci/bottles-num"
    sha256 cellar: :any, catalina:     "8e99032961f74428c0ebcbc8712c2347c9598a2d4e1a888743b745397ae3701e"
    sha256 cellar: :any, x86_64_linux: "ada4f3010e86b867c4dfc4fafab3028cc8913c349d91d971892d86ece417d9f9"
  end

  keg_only "formulae in brewsci/num are keg only"

  depends_on "gcc"
  depends_on "openblas"
  depends_on "open-mpi" => :recommended

  if build.with? "open-mpi"
    depends_on "scalapack"
    depends_on "brewsci/num/brewsci-parmetis" => :recommended
  else
    depends_on "brewsci/num/brewsci-metis" => :recommended
  end

  depends_on "brewsci/num/brewsci-scotch" => :optional
  depends_on "brewsci/num/brewsci-scotch@5" => :optional

  fails_with :clang # because we use OpenMP

  resource "mumps_simple" do
    url "https://github.com/dpo/mumps_simple/archive/v0.4.tar.gz"
    sha256 "87d1fc87eb04cfa1cba0ca0a18f051b348a93b0b2c2e97279b23994664ee437e"
  end

  def install
    # MUMPS 5.3.4 does not compile with gfortran10. Allow some errors to go through.
    # see https://listes.ens-lyon.fr/sympa/arc/mumps-users/2020-10/msg00002.html
    make_args = ["RANLIB=echo", "CDEFS=-DAdd_"]
    optf = ["OPTF=-O"]
    gcc_major_ver = Formula["gcc"].any_installed_version.major
    optf << "-fallow-argument-mismatch" if gcc_major_ver >= 10
    make_args << optf.join(" ")
    orderingsf = "-Dpord"

    makefile = build.with?("open-mpi") ? "Makefile.G95.PAR" : "Makefile.G95.SEQ"
    cp "Make.inc/" + makefile, "Makefile.inc"

    lib_args = []

    if build.with? "brewsci-scotch@5"

      scotch_dir = Formula["brewsci-scotch@5"].opt_prefix
      make_args += ["SCOTCHDIR=#{scotch_dir}", "ISCOTCH=-I#{Formula["brewsci-scotch@5"].opt_include}"]

      if build.with? "open-mpi"
        scotch_libs = "-L$(SCOTCHDIR)/lib -lptesmumps -lptscotch -lptscotcherr"
        scotch_libs += " -lptscotchparmetis" if build.with? "brewsci-parmetis"
        orderingsf << " -Dptscotch"
      else
        scotch_libs = "-L$(SCOTCHDIR)/lib -lesmumps -lscotch -lscotcherr"
        scotch_libs += " -lscotchmetis" if build.with? "brewsci-metis"
        orderingsf << " -Dscotch"
      end
      make_args << "LSCOTCH=#{scotch_libs}"
      lib_args += scotch_libs.split

    elsif build.with? "brewsci-scotch"

      scotch_dir = Formula["brewsci-scotch"].opt_prefix
      make_args += ["SCOTCHDIR=#{scotch_dir}", "ISCOTCH=-I#{Formula["brewsci-scotch"].opt_include}"]

      if build.with? "open-mpi"
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

    if build.with? "open-mpi"
      scalapack_libs = "-L#{Formula["scalapack"].opt_lib} -lscalapack"
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
    make_args << "LAPACK=#{blas_lib}"
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
    if build.without? "open-mpi"
      cd "libseq" do
        libmpiseq_install_name = install_name.call("libmpiseq")
        system compiler, "-fPIC", "-shared", "-Wl,#{all_load}", "libmpiseq.a", *lib_args, \
               "-Wl,#{noall_load}", *libmpiseq_install_name, *shopts, "-o", "libmpiseq.#{so}"
      end
    end

    lib.install Dir["lib/*"]
    lib.install "libseq/libmpiseq.#{so}" if build.without? "open-mpi"

    inreplace "examples/Makefile" do |s|
      s.change_make_var! "libdir", lib
    end

    libexec.install "include"
    include.install_symlink Dir[libexec/"include/*"]
    # The following .h files may conflict with others related to MPI
    # in /usr/local/include. Do not symlink them.
    (libexec/"include").install Dir["libseq/*.h"] if build.without? "open-mpi"

    doc.install Dir["doc/*.pdf"]
    pkgshare.install "examples"

    prefix.install "Makefile.inc"  # For the record.
    File.open(prefix/"make_args.txt", "w") do |f|
      f.puts(make_args.join(" "))  # Record options passed to make.
    end

    if build.with? "open-mpi"
      resource("mumps_simple").stage do
        simple_args = ["CC=mpicc", "prefix=#{prefix}", "mumps_prefix=#{prefix}",
                       "scalapack_libdir=#{Formula["scalapack"].opt_lib}"]
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
    if build.without? "open-mpi"
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
    if Tab.for_name("brewsci-mumps").with?("open-mpi")
      mpiopts = ""
      if OS.linux?
        if ENV["CI"]
          mpiopts = "--allow-run-as-root"
          ENV["OMPI_ALLOW_RUN_AS_ROOT"] = "1"
          ENV["OMPI_ALLOW_RUN_AS_ROOT_CONFIRM"] = "1"
        end
        ENV.prepend_path "LD_LIBRARY_PATH", Formula["scalapack"].opt_lib
      end
      f90 = "mpif90"
      cc = "mpicc"
      mpirun = "mpirun -np 1 #{mpiopts}"
      includes = "-I#{opt_include}"
      opts << "-L#{Formula["scalapack"].opt_lib}" << "-lscalapack" << "-L#{opt_lib}"
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
      system(*(mpirun.split + ["./c_example"] + opts))
    end
  end
end
