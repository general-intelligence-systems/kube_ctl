# frozen_string_literal: true

task :test do
  Dir["lib/**/*.rb"].sort.each do |f|
    sh "ruby", "-I", "lib", "-rminitest/autorun", "-rkube/ctl", f
  end
end

task default: :test
