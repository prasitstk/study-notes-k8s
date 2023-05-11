require "sinatra"

set :bind, "0.0.0.0"

# v1
# get "*" do
#   "[v1] Hello, Kubernetes!\n"
# end

# v2 for rolling update
# get "*" do
#   "[v2] Hello, Kubernetes!\n"
# end

# buggy for undo deployment
$counter = 0

get "*" do
  $counter += 1
  if $counter > 3
    raise "Whoops, something is wrong"
  end

  "[buggy] Hello, Kubernetes!\n"
end
