Backend of [wrinq.com](http://www.wrinq.com/)


#### Building and running wrinq-core.

1. Make sure that [redis](http://redis.io/) is installed and running. By default wrinq listens for redis on port 6739. If you are running it on a different port you should initialize redis as `eredis:start_link("ip address",portnumber)` [on tihs line](https://github.com/brickcap/wrinq-core/blob/master/src/wrinq_app.erl#L9)

2. Clone this repository.
3. The repository includes executable scripts for fetching the depedencies, building the project and generating a release.
4. To fetch the dependencies and build the project `cd` to the location of cloned repository and type `rebar get-deps compile`
5. To generate a release type `relx`.
6. After this you should have an _rel folder in the parent directory. To run wrinq `cd \_rel` and type `bin\wrinq console`to start it with an erlang shell or `bin/wrinq start` for running it without a shell. Note if you are running on a production server start it without a shell so that it keeps running afer you quit the terminal.

7. The _rel folder generated in step 5 is self contained. Meaning it can be just copied to your server and run from there without installing erlang and any other dependencies of the project. Redis however needs to be installed seperately.   

8. wrinq-core does not include the front end of wrinq. All it does is to accept web socket connections and forward them to the appropriate channel. Check out [wrinq-front-end repository](https://github.com/brickcap/wrinq-front-end) for instructions on running wrinq's front-end.      