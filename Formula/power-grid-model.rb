# SPDX-FileCopyrightText: Contributors to the Power Grid Model project <powergridmodel@lfenergy.org>
#
# SPDX-License-Identifier: MPL-2.0

class PowerGridModel < Formula
  desc "Python/C++ library for distribution power system analysis"
  homepage "https://lfenergy.org/projects/power-grid-model/"
  url "https://github.com/PowerGridModel/power-grid-model/archive/refs/tags/v1.13.126.tar.gz"
  sha256 "4596246aca9f9be5382a025f60d4c1bfcd14a7408d2cc4649c04027aeb0caf5b"
  license "MPL-2.0"
  head "https://github.com/PowerGridModel/power-grid-model.git", branch: "main"

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "eigen" => :build
  depends_on "gcc@14" => :build
  depends_on "msgpack-cxx" => :build
  depends_on "ninja" => :build
  depends_on "nlohmann-json" => :build

  def install
    rm buildpath/"VERSION"
    (buildpath/"VERSION").write(version.to_s)
    begin
      system_gcc_version = Utils.safe_popen_read("gcc", "-dumpversion").strip.to_i
    rescue
      system_gcc_version = 0
    end

    user_cxx = ENV["CXX"].to_s
    user_cc  = ENV["CC"].to_s
    using_non_gcc = (!user_cxx.empty? && user_cxx.exclude?("g++")) ||
                    (!user_cc.empty?  && user_cc.exclude?("gcc"))

    # If the user has not requested a non-GCC compiler and the system GCC version is less than 14,
    # use the GCC 14 compiler from Homebrew.
    # This minimum was added because we use some features in PGM not available in older versions of GCC.
    if !using_non_gcc && system_gcc_version < 14
      gcc = Formula["gcc@14"]
      system "cmake", "-GNinja", "-S", ".", "-B", "build",
             "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-14",
             "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-14",
             *std_cmake_args
    else
      system "cmake", "-GNinja", "-S", ".", "-B", "build",
             *std_cmake_args
    end
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "power_grid_model_c.h"

      #include <iostream>
      #include <memory>

      namespace {
      // custom deleter
      template <auto func> struct DeleterFunctor {
          template <typename T> void operator()(T* arg) const { func(arg); }
      };

      using HandlePtr = std::unique_ptr<PGM_Handle, DeleterFunctor<&PGM_destroy_handle>>;
      } // namespace

      auto main() -> int {
          // get handle from C-API
          HandlePtr const c_handle{PGM_create_handle()};
          std::cout << (c_handle ? "Handle created: C-API is available.\\n" : "No handle could be created.\\n");
          int return_code = (c_handle != nullptr) ? 0 : 1;
          return return_code;
      }
    CPP
    system ENV.cxx, "test.cpp", "--std=c++17", "-I#{include}", "-L#{lib}", "-lpower_grid_model_c", "-o", "test"
    system "./test"
  end
end
