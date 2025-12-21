#!/usr/bin/env bats

load 'test_helper'

@test "build.sh creates the build directory" {
  run "${BATS_TEST_DIRNAME}/../build.sh"
  assert_exit_success "$status"
  assert_directory_exists "${BATS_TEST_DIRNAME}/../../build"
}

@test "build.sh creates the index.html file" {
  run "${BATS_TEST_DIRNAME}/../build.sh"
  assert_exit_success "$status"
  assert_file_exists "${BATS_TEST_DIRNAME}/../../build/index.html"
}

@test "build.sh creates the static directory" {
  run "${BATS_TEST_DIRNAME}/../build.sh"
  assert_exit_success "$status"
  assert_directory_exists "${BATS_TEST_DIRNAME}/../../build/static"
}

@test "build.sh creates static in the static directory" {
  run "${BATS_TEST_DIRNAME}/../build.sh"
  assert_exit_success "$status"
  run ls "${BATS_TEST_DIRNAME}/../../build/static"
  assert_contains "$output" ".js"
}
