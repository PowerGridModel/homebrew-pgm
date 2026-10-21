# SPDX-FileCopyrightText: Contributors to the Power Grid Model project <powergridmodel@lfenergy.org>
#
# SPDX-License-Identifier: MPL-2.0

class PowerGridModel < Formula
  desc "Python/C++ library for distribution power system analysis"
  homepage "https://lfenergy.org/projects/power-grid-model/"
  url "https://github.com/PowerGridModel/power-grid-model/archive/refs/tags/v1.13.197.tar.gz"
  sha256 "2d677450c70d92014541877eb4339cb56266b0d82a11cca541e5af99dd4e8630"
  license "MPL-2.0"
  head "https://github.com/PowerGridModel/power-grid-model.git", branch: "main"

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "eigen" => :build
  depends_on "msgpack-cxx" => :build
  depends_on "ninja" => :build
  depends_on "nlohmann-json" => :build

  on_linux do
    depends_on "gcc@16" => :build
  end

  fails_with :gcc do
    version "15"
    cause "Use the same GCC version as in main PGM"
  end

  def install
    rm buildpath/"VERSION"
    (buildpath/"VERSION").write(version.to_s)
    system "cmake", "-GNinja", "-S", ".", "-B", "build", *std_cmake_args
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
