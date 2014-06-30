/**
 * Copyright (C) 2014 Wesleyan University
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
  $(document).ready(function() {
//    Tp.projectorPane = new Tp.ProjectorPaneView;
//    Tp.actionListView = new Tp.ActionListView;
    
    Tp.outputPane = new Tp.OutputPaneView;
    return Tp.inputListView = new Tp.InputListView;
    //Tp.inputListView = new Tp.InputListView;

    //return Tp.contextView = new Tp.ContextView;
  });

}).call(this);
