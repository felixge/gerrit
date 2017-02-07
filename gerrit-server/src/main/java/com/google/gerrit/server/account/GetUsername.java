// Copyright (C) 2013 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.google.gerrit.server.account;

import com.google.gerrit.extensions.restapi.AuthException;
import com.google.gerrit.extensions.restapi.ResourceNotFoundException;
import com.google.gerrit.extensions.restapi.RestReadView;
import com.google.inject.Inject;
import com.google.inject.Singleton;

@Singleton
public class GetUsername implements RestReadView<AccountResource> {
  @Inject
  public GetUsername() {}

  @Override
  public String apply(AccountResource rsrc) throws AuthException, ResourceNotFoundException {
    String username = rsrc.getUser().getAccount().getUserName();
    if (username == null) {
      throw new ResourceNotFoundException();
    }
    return username;
  }
}
