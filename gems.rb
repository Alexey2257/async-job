source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
	gem "sus"
	gem "covered"
	
	gem "bake-test"
	gem "bake-test-external"
end
