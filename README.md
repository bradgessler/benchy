# Benchy

I wrote this one day because I was trying to test upload performance and no tools out there were cutting it. You can do sane stuff like:

```
benchy post http://127.0.0.1:8080/ -c 10 < my_pic.jpg # Simulates 10 concurrent HTTP POST requests
```

or

```
benchy get http://127.0.0.1:8080/ # Just run a bunch of GET requests at a concurrency of 1
```

and it runs indefintely until you kill the process.

# Getting Started

Install benchie:

```
gem install benchy
```

Then run a command! As you'd expect:

```
$ benchy help
Tasks:
  benchy delete URL   # Perform DELETE requests against a URL
  benchy get URL      # Perform GET requests against a URL
  benchy head URL     # Perform HEAD requests against a URL
  benchy help [TASK]  # Describe available tasks or one specific task
  benchy post URL     # Perform POST requests to a URL
  benchy put URL      # Perform PUT requests to a URL
```