#!/bin/sh

set -eu

DIR=$( dirname "$0" )/../..

# NOTE: These statuses have a lot more information in them.

cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > $TMPDIR/http.req-$$ &
HTTP/1.0 200 OK

[
  {
    "created_at": "2012-07-20T01:19:13Z",
    "updated_at": "2012-07-20T01:19:13Z",
    "state": "success",
    "target_url": "https://ci.example.com/1000/output",
    "description": "Build has completed successfully",
    "id": 1,
    "url": "https://api.github.com/repos/octocat/Hello-World/statuses/1",
    "context": "continuous-integration/jenkins"
  },
  {
    "created_at": "2012-08-20T01:19:13Z",
    "updated_at": "2012-08-20T01:19:13Z",
    "state": "success",
    "target_url": "https://ci.example.com/2000/output",
    "description": "Testing has completed successfully",
    "id": 2,
    "url": "https://api.github.com/repos/octocat/Hello-World/statuses/2",
    "context": "security/brakeman"
  }
]
EOF

in_dir=$TMPDIR/status-$$

mkdir $in_dir

$DIR/bin/in "$in_dir" > $TMPDIR/resource-$$ <<EOF
{
  "version": {
    "commit": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "status": "2"
  },
  "source": {
    "access_token": "test-token",
    "context": "test-context",
    "endpoint": "http://127.0.0.1:9192",
    "repository": "dpb587/test-repo"
  }
}
EOF

if ! grep -q '^GET /repos/dpb587/test-repo/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/status ' $TMPDIR/http.req-$$ ; then
  echo "FAILURE: Invalid HTTP method or URI"
  cat $TMPDIR/http.req-$$
  exit 1
fi

if ! [[ "6dcb09b5b57875f334f61aebed695e2e4193db5e" == "$( cat $in_dir/commit )" ]] ; then
  echo "FAILURE: Unexpected /commit data"
  cat "$in_dir/commit"
  exit 1
fi

if ! [[ "Testing has completed successfully" == "$( cat $in_dir/description )" ]] ; then
  echo "FAILURE: Unexpected /description data"
  cat "$in_dir/description"
  exit 1
fi

if ! [[ "success" == "$( cat $in_dir/state )" ]] ; then
  echo "FAILURE: Unexpected /state data"
  cat "$in_dir/state"
  exit 1
fi

if ! [[ "https://ci.example.com/2000/output" == "$( cat $in_dir/target_url )" ]] ; then
  echo "FAILURE: Unexpected /target_url data"
  cat "$in_dir/target_url"
  exit 1
fi

if ! [[ "2012-08-20T01:19:13Z" == "$( cat $in_dir/updated_at )" ]] ; then
  echo "FAILURE: Unexpected /updated_at data"
  cat "$in_dir/updated_at"
  exit 1
fi

if ! grep -q '"version":{"commit":"6dcb09b5b57875f334f61aebed695e2e4193db5e","status":"2"}' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected version output"
  cat $TMPDIR/resource-$$
  exit 1
fi

if ! grep -q '{"name":"created_at","value":"2012-08-20T01:19:13Z"}' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected created_at output"
  cat $TMPDIR/resource-$$
  exit 1
fi
