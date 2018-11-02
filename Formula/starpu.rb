class Starpu < Formula
  desc "Unified Runtime System for Heterogeneous Multicore Architectures"
  homepage "http://starpu.gforge.inria.fr/"
  url "http://starpu.gforge.inria.fr/files/starpu-1.2.6/starpu-1.2.6.tar.gz"
  sha256 "eb67a7676777b6ed583722aca5a9f63145b842f390ac2f5b3cbc36fe910d964c"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles-num"
    sha256 "eb9757a75eeb7f82d1c5baffcfcd6dc6e95a7c23a8f840d47e2e1b91741dd88e" => :sierra
    sha256 "7b0450cf223d60fd11bec88cadb77aa12c754168a86bfb5a1c3b8461e9d93d7e" => :x86_64_linux
  end

  head do
    url "https://scm.gforge.inria.fr/anonscm/git/starpu/starpu.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "openblas"
  end

  option "with-openmp", "Enable OpenMP multithreading"

  depends_on "gcc" if build.with? "openmp"
  depends_on "hwloc"
  depends_on "pkg-config"

  fails_with :clang if build.with? "openmp"

  def install
    if build.head?
      ENV["LIBTOOL"] = "glibtool"
      system "./autogen.sh"
    end

    mkdir "build" do
      args = ["--disable-debug",
              "--disable-dependency-tracking",
              "--disable-silent-rules",
              "--enable-quick-check",
              "--disable-build-examples",
              "--bindir=#{libexec}/bin",
              "--without-x",
              "--enable-blas-lib=openblas",
              "--prefix=#{prefix}"]
      args << "--enable-openmp" if build.with? "openmp"

      system "../configure", *args
      system "make"
      system "make", "check"
      system "make", "install"
      %w[starpu_calibrate_bus starpu_codelet_histo_profile starpu_codelet_profile
         starpu_lp2paje starpu_machine_display starpu_paje_state_stats
         starpu_perfmodel_display starpu_perfmodel_plot starpu_sched_display
         starpu_tasks_rec_complete starpu_temanejo2.sh].each do |f|
        bin.install_symlink "#{libexec}/bin/#{f}"
      end
    end
  end

  test do
    (testpath/"hello-starpu.c").write <<~EOF
      #include <stdio.h>
      static void my_task (int x) __attribute__ ((task));
      static void my_task (int x) {
        printf ("Hello, world!  With x = %d\\n", x);
      }
      int main (void) {
        #pragma starpu initialize
        my_task (42);
        #pragma starpu wait
        #pragma starpu shutdown
        return 0;
      }
    EOF

    ENV.prepend_path "PKG_CONFIG_PATH", Formula["hwloc"].opt_prefix

    ver = Formula["starpu"].version.to_f # should be 1.2
    cflags = `#{Formula["pkg-config"].opt_bin}/pkg-config starpu-#{ver} --cflags`
    libs = `#{Formula["pkg-config"].opt_bin}/pkg-config starpu-#{ver} --libs`
    system ENV["CC"], "hello-starpu.c", *(cflags.split + libs.split)
    assert_match "x = 42", shell_output("./a.out 2>&1")
  end
end
