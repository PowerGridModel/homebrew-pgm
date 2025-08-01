# SPDX-FileCopyrightText: Contributors to the Power Grid Model project <powergridmodel@lfenergy.org>
#
# SPDX-License-Identifier: MPL-2.0

class PowerGridModel < Formula
  desc "Python/C++ library for distribution power system analysis"
  homepage "https://lfenergy.org/projects/power-grid-model/"
  url "https://github.com/PowerGridModel/power-grid-model/archive/refs/tags/v1.11.38.tar.gz"
  sha256 "c38eafc31849065435bc00e9df70c6a1624d0567e5a8a5d76a31aa50f892b1cb"
  license "MPL-2.0"
  head "https://github.com/PowerGridModel/power-grid-model.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "boost" => :build
  depends_on "eigen" => :build
  depends_on "nlohmann-json" => :build
  depends_on "msgpack-cxx" => :build
  depends_on "ninja" => :build


  def install
    system "rm", "VERSION"
    (buildpath/"VERSION").write("#{version}")
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
