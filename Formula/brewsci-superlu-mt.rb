class BrewsciSuperluMt < Formula
  desc "Multithreaded solution of large, sparse nonsymmetric systems"
  homepage "https://portal.nersc.gov/project/sparse/superlu"
  url "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_mt_3.1.tar.gz"
  sha256 "407b544b9a92b2ed536b1e713e80f986824cf3016657a4bfc2f3e7d2a76ecab6"
  revision 1

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "bc03251ee6067ed8753fc81a8a6faa03c5d669463fd24d7a4b88583d1635187d" => :sierra
    sha256 "561c5bb9188496dffbfcc1d04c2e81c2849880b202da2f8d965e0e026ffa1428" => :x86_64_linux
  end

  keg_only "formulae in brewsci/num are keg only"

  # Accelerate single precision is buggy and causes certain single precision
  # tests to fail.
  depends_on "openblas"
  depends_on "tcsh" if OS.linux?
  depends_on "gcc" => :optional

  def install
    ENV.deparallelize
    make_args = %W[CC=#{ENV.cc} CFLAGS=#{ENV.cflags} FORTRAN= LOADER=#{ENV.cc}]

    if build.with? "gcc"
      make_inc = "make.openmp"
      libname = "libsuperlu_mt_OPENMP.a"
      ENV.append_to_cflags "-D__OPENMP"
      make_args << "MPLIB=-fopenmp"
      make_args << "PREDEFS=-D__OPENMP -fopenmp"
    else
      make_inc = "make.pthread"
      libname = "libsuperlu_mt_PTHREAD.a"
      ENV.append_to_cflags "-D__PTHREAD"
    end
    cp "MAKE_INC/#{make_inc}", "make.inc"

    make_args << "BLASLIB=-L#{Formula["openblas"].opt_lib} -lopenblas"

    system "make", *make_args
    lib.install Dir["lib/*.a"]
    ln_s lib/libname, lib/"libsuperlu_mt.a"
    (include/"superlu_mt").install Dir["SRC/*.h"]
    pkgshare.install "EXAMPLE"
    doc.install Dir["DOC/*.pdf"]
    prefix.install "make.inc"
    File.open(prefix/"make_args.txt", "w") do |f|
      make_args.each do |arg|
        var, val = arg.split("=")
        f.puts "#{var}=\"#{val}\"" # Record options passed to make, preserve spaces.
      end
    end
  end

  def caveats
    <<~EOS
      Default SuperLU_MT build options are recorded in

        #{opt_prefix}/make.inc

      Specific options for this build are in

        #{opt_prefix}/make_args.txt
    EOS
  end

  test do
    cp_r pkgshare/"EXAMPLE", testpath
    cp prefix/"make.inc", testpath
    make_args = []
    File.readlines(opt_prefix/"make_args.txt").each do |line|
      make_args << line.chomp.delete('\\"')
    end
    make_args << "HEADER=#{opt_include}/superlu_mt"
    make_args << "LOADOPTS="
    make_args << "CC=gcc -Wno-implicit-function-declaration"

    cd "EXAMPLE" do
      inreplace "Makefile", "../lib/$(SUPERLULIB)", "#{opt_lib}/libsuperlu_mt.a"
      system "make", *make_args
      # simple driver
      system "./pslinsol -p 2 < big.rua"
      system "./pdlinsol -p 2 < big.rua"
      system "./pclinsol -p 2 < cmat"
      system "./pzlinsol -p 2 < cmat"
      # expert driver
      system "./pslinsolx -p 2 < big.rua"
      system "./pdlinsolx -p 2 < big.rua"
      system "./pclinsolx -p 2 < cmat"
      system "./pzlinsolx -p 2 < cmat"
      # expert driver on several systems with same sparsity pattern
      system "./pslinsolx1 -p 2 < big.rua"
      system "./pdlinsolx1 -p 2 < big.rua"
      system "./pclinsolx1 -p 2 < cmat"
      system "./pzlinsolx1 -p 2 < cmat"
      # example with symmetric mode
      system "./pslinsolx2 -p 2 < big.rua"
      system "./pdlinsolx2 -p 2 < big.rua"
      # system "./pclinsolx2 -p 2 < cmat" # bus error
      # system "./pzlinsolx2 -p 2 < cmat" # bus error
      # example with repeated factorization of systems with same sparsity pattern
      # system "./psrepeat -p 2 < big.rua" # malloc error
      # system "./pdrepeat -p 2 < big.rua" # malloc error
      # system "./pcrepeat -p 2 < cmat" # malloc error
      # system "./pzrepeat -p 2 < cmat" # malloc error
      # example that integrates with other multithreaded application
      system "./psspmd -p 2 < big.rua"
      system "./pdspmd -p 2 < big.rua"
      system "./pcspmd -p 2 < cmat"
      system "./pzspmd -p 2 < cmat"
    end
  end
end
