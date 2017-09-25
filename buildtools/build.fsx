#r @"tmp/FAKE/tools/FakeLib.dll"
#load "helper_functions.fsx"

open System
open System.IO
open Fake
open Fake.NuGet.Install
open Fake.DotNetCli

let cppClientVersion = "8.2.0.Alpha1"
let swigVersion = "3.0.12"
let protobufVersion = "3.4.0" // if changing this, be sure to also update Google.Protobuf in src/Infinispan.HotRod/Infinispan.HotRod.csproj

let buildDir = "../build"
let generateDir = "../src/Infinispan.HotRod/generated"
let generateTestDir = "../test/Infinispan.HotRod.Tests/generated"

Target "Clean" (fun _ ->
    // git will not preserve empty folders, so ensure they exist because the tools expect them to exist and clean them
    [buildDir; generateDir; generateTestDir]
        |> Seq.iter ensureDirectory
    CleanDirs [buildDir; generateDir; generateTestDir]
)

Target "GenerateProto" (fun _ ->
    trace "running generation of proto files"
    let protocLocation = downloadProtocIfNonexist protobufVersion
    generateCSharpFromProtoFiles protocLocation "../protos" generateDir
    trace "proto files generated"
)

Target "GenerateProtoForTests" (fun _ ->
    trace "running generation of proto files for tests"
    let protocLocation = downloadProtocIfNonexist protobufVersion
    generateCSharpFromProtoFiles protocLocation "../test/resources/proto3" ("../../" + generateTestDir)
    trace "proto files for tests generated"
)

Target "GenerateSwig" (fun _ ->
    trace "running swig generation"
    let cppClientLocation = downloadCppClientIfNonexist cppClientVersion
    let swigToolPath = downloadSwigToolsIfNonexist swigVersion
    let cppClientInclude = @"..\buildtools" @@ cppClientLocation @@ "include" // remember, it's gonna run from ../swig folder
    let sourceDir = "../swig"
    let _namespace = "Infinispan.HotRod.SWIGGen"
    generateCSharpFilesFromSwigTemplates swigToolPath cppClientInclude sourceDir _namespace generateDir
    trace "swig generated"
)

Target "Generate" (fun _ ->
    trace "proto files and swig files generated"
)

Target "SetVersion" (fun _ ->
    trace "version set"
)

Target "Build" (fun _ ->
    Build (fun p -> { p with Project = "../Infinispan.HotRod.sln"})
    trace "solution built"
)

Target "UnitTest" (fun _ ->
    trace "unit tests done"
)

Target "IntegrationTest" (fun _ ->
    trace "integration tests done"
)

Target "Publish" (fun _ ->
    trace "published"
)

// targets chain
"Clean" ==> "GenerateProto" ==> "GenerateProtoForTests" ==> "GenerateSwig" ==> "Generate" ==> "SetVersion" ==> "Build"
    ==> "UnitTest" ==> "IntegrationTest" ==> "Publish"

RunParameterTargetOrDefault "target" "Build"