class BrewsciSuperluDist < Formula
  desc "Distributed LU factorization for large linear systems"
  homepage "https://portal.nersc.gov/project/sparse/superlu"
  url "https://github.com/xiaoyeli/superlu_dist/archive/v6.4.0.tar.gz"
  sha256 "cb9c0b2ba4c28e5ed5817718ba19ae1dd63ccd30bc44c8b8252b54f5f04a44cc"
  head "https://github.com/xiaoyeli/superlu_dist"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    sha256 catalina:     "19de106830a2558b4f5bcc5888b31ba18b1ddb1f55fe898a2c299595dbcc6a5f"
    sha256 x86_64_linux: "03113b91f2b248d35cffc252cbfb46dec5261b5c9b4ea85aad25f6395eaaca91"
  end

  keg_only "formulae in brewsci/num are keg only"

  depends_on "cmake" => :build
  depends_on "brewsci/num/brewsci-parmetis"
  depends_on "gcc"
  depends_on "open-mpi"
  depends_on "openblas"

  def install
    # prevent linking errors on linux
    ENV.deparallelize

    dylib_ext = OS.mac? ? "dylib" : "so"

    parmetis_libs = [
      "#{Formula["brewsci-parmetis"].opt_lib}/libparmetis.#{dylib_ext}",
      "#{Formula["brewsci-metis"].opt_lib}/libmetis.#{dylib_ext}",
    ]
    parmetis_include_dirs = [
      Formula["brewsci-parmetis"].opt_include.to_s,
      Formula["brewsci-metis"].opt_include.to_s,
    ]

    cmake_args = std_cmake_args
    cmake_args << "-DTPL_PARMETIS_LIBRARIES=#{parmetis_libs.join ";"}"
    cmake_args << "-DTPL_PARMETIS_INCLUDE_DIRS=#{parmetis_include_dirs.join ";"}"
    cmake_args << "-DCMAKE_C_FLAGS=-fPIC -O2"
    cmake_args << "-DBUILD_SHARED_LIBS=ON"
    cmake_args << "-DCMAKE_C_COMPILER=mpicc"
    cmake_args << "-DCMAKE_Fortran_COMPILER=mpif90"
    cmake_args << "-DCMAKE_INSTALL_PREFIX=#{prefix}"
    cmake_args << "-DTPL_BLAS_LIBRARIES=-L#{Formula["openblas"].opt_lib} -lopenblas"

    mkdir "build" do
      system "cmake", "..", *cmake_args
      system "make"
      system "make", "install"
      # system "make", "test"
    end

    doc.install "DOC/ug.pdf"
    pkgshare.install "EXAMPLE"
  end

  test do
    cp pkgshare/"EXAMPLE/dcreate_matrix.c", testpath
    cp pkgshare/"EXAMPLE/pddrive.c", testpath
    cp pkgshare/"EXAMPLE/g20.rua", testpath
    args = [
      "-I#{Formula["brewsci-superlu-dist"].opt_include}",
      "-L#{Formula["brewsci-superlu-dist"].opt_lib}",
      "-lsuperlu_dist",
    ]
    ENV.prepend_path "LD_LIBRARY_PATH", opt_lib unless OS.mac?
    system "mpicc", "-o", "pddrive", "pddrive.c", "dcreate_matrix.c", *args
    return if OS.linux? && ENV["GITHUB_ACTIONS"]

    output = shell_output("mpirun -np 4 ./pddrive -r 2 -c 2 g20.rua")
    accuracy = ((output.lines.grep /Sol  0/)[-1]).to_f
    assert accuracy < 1.0e-8
  end
end
