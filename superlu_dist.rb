class SuperluDist < Formula
  desc "Distributed LU factorization for large linear systems"
  homepage "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/"
  url "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_dist_5.1.0.tar.gz"
  sha256 "30ac554a992441e6041c6fb07772da4fa2fa6b30714279de03573c2cad6e4b60"
  revision 1

  bottle do
    sha256 "832ef134b3f34d13f990ab01cd09042f2eb7e6fa0c3c3c8dd8dcd7eb0dd19109" => :el_capitan
    sha256 "77863960780d6b70ee0020cbf351c04f57390411f73d388852e0a6795412269e" => :yosemite
    sha256 "56acc4159cf7b0f16dee6705e4308935280daa2a287514d37c631d4a878bdbab" => :mavericks
  end

  option "without-test", "skip build-time tests (not recommended)"
  option "with-openmp", "Enable OpenMP multithreading"
  needs :openmp if build.with? "openmp"

  depends_on "cmake" => :build
  depends_on :fortran
  depends_on :mpi => [:cc, :f77, :f90]

  depends_on "parmetis"
  depends_on "openblas" => OS.mac? ? :optional : :recommended
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  def install
    # prevent linking errors on linuxbrew:
    ENV.deparallelize

    cmake_args = std_cmake_args
    cmake_args << "-DTPL_PARMETIS_LIBRARIES=#{Formula["parmetis"].opt_lib}/libparmetis.dylib;#{Formula["metis"].opt_lib}/libmetis.dylib"
    cmake_args << "-DTPL_PARMETIS_INCLUDE_DIRS=#{Formula["parmetis"].opt_include};#{Formula["metis"].opt_include}"
    cmake_args << "-DCMAKE_C_FLAGS=-fPIC -O2"
    cmake_args << "-DBUILD_SHARED_LIBS=ON"
    cmake_args << "-DCMAKE_C_COMPILER=#{ENV["MPICC"]}"
    cmake_args << "-DCMAKE_Fortran_COMPILER=#{ENV["MPIF90"]}"
    cmake_args << "-DCMAKE_INSTALL_PREFIX=#{prefix}"

    blaslib = ((build.with? "openblas") ? "-L#{Formula["openblas"].opt_lib} -lopenblas" : "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort")
    cmake_args << "-DTPL_BLAS_LIBRARIES=#{blaslib}"

    mkdir "build" do
      system "cmake", "..", *cmake_args
      system "make"
      system "make", "install"
      system "make", "test" if build.with? "test"
    end

    doc.install "DOC/ug.pdf"
    pkgshare.install "EXAMPLE"
  end

  test do
    ENV.fortran
    cp pkgshare/"EXAMPLE/dcreate_matrix.c", testpath
    cp pkgshare/"EXAMPLE/pddrive.c", testpath
    cp pkgshare/"EXAMPLE/g20.rua", testpath
    system "mpicc", "-o", "pddrive", "pddrive.c", "dcreate_matrix.c", "-L#{Formula["superlu_dist"].opt_lib}", "-lsuperlu_dist"
    system "mpirun", "-np", "4", "./pddrive", "-r", "2", "-c", "2", "g20.rua"
  end
end
