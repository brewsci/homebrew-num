class BrewsciScalapack < Formula
  desc "High-performance distributed memory linear algebra"
  homepage "https://www.netlib.org/scalapack/"
  url "https://www.netlib.org/scalapack/scalapack-2.0.2.tgz"
  sha256 "0c74aeae690fe5ee4db7926f49c5d0bb69ce09eea75beb915e00bba07530395c"
  revision 1

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    cellar :any
    sha256 "1c2e20e165af5432b7e3d45fa4d39da741acbf09a0e17a63df33f06c85770795" => :sierra
    sha256 "ae44dfe1ac56dc5503da3634e292ce6ec5951cac94b5df996f9a542f48944867" => :x86_64_linux
  end

  keg_only "scalapack is already provided by homebrew/core"

  depends_on "cmake" => :build
  depends_on "gcc"
  depends_on "open-mpi"
  depends_on "openblas"

  # https://gitlab.kitware.com/cmake/cmake/issues/18817
  patch :DATA

  def install
    blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"

    mkdir "build" do
      system "cmake", "..", *std_cmake_args, "-DBUILD_SHARED_LIBS=ON",
                      "-DBLAS_LIBRARIES=#{blas}", "-DLAPACK_LIBRARIES=#{blas}"
      system "make", "all"
      system "make", "install"
    end

    pkgshare.install "EXAMPLE"
  end

  test do
    ENV.fortran
    cp_r pkgshare/"EXAMPLE", testpath
    cd "EXAMPLE" do
      system "mpif90", "-o", "xsscaex", "psscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert `mpirun -np 4 ./xsscaex | grep 'INFO code' | awk '{print $NF}'`.to_i.zero?
      system "mpif90", "-o", "xdscaex", "pdscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert `mpirun -np 4 ./xdscaex | grep 'INFO code' | awk '{print $NF}'`.to_i.zero?
      system "mpif90", "-o", "xcscaex", "pcscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert `mpirun -np 4 ./xcscaex | grep 'INFO code' | awk '{print $NF}'`.to_i.zero?
      system "mpif90", "-o", "xzscaex", "pzscaex.f", "pdscaexinfo.f", "-L#{opt_lib}", "-lscalapack"
      assert `mpirun -np 4 ./xzscaex | grep 'INFO code' | awk '{print $NF}'`.to_i.zero?
    end
  end
end

__END__
diff --git a/CMAKE/FortranMangling.cmake b/CMAKE/FortranMangling.cmake
index e9642ed..e40cac0 100644
--- a/CMAKE/FortranMangling.cmake
+++ b/CMAKE/FortranMangling.cmake
@@ -18,6 +18,7 @@ FUNCTION(COMPILE RESULT)
     EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND}
          "-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}"
          "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
+         ${PROJECT_SOURCE_DIR}/BLACS/INSTALL/
         WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/BLACS/INSTALL/
         RESULT_VARIABLE RESVAR OUTPUT_VARIABLE LOG1 ERROR_VARIABLE LOG1
     )
