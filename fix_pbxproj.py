import os

pbxproj_path = '/home/ubuntu/OkulAI/ios/Runner.xcodeproj/project.pbxproj'
with open(pbxproj_path, 'r') as f:
    content = f.read()

if 'GoogleService-Info.plist' not in content:
    # Add FileReference
    file_ref = '97C147021CF9000F007C117D /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };'
    new_ref = 'D7C147021CF9000F007C117D /* GoogleService-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "GoogleService-Info.plist"; sourceTree = "<group>"; };'
    content = content.replace(file_ref, file_ref + '\n' + new_ref)
    
    # Add to PBXGroup
    group_ref = '97C147021CF9000F007C117D /* Info.plist */,'
    new_group_ref = 'D7C147021CF9000F007C117D /* GoogleService-Info.plist */,'
    content = content.replace(group_ref, group_ref + '\n' + new_group_ref)
    
    # Add to PBXResourcesBuildPhase
    resource_ref = '97C147011CF9000F007C117D /* LaunchScreen.storyboard in Resources */,'
    new_resource_ref = 'D7C147021CF9000F007C117D /* GoogleService-Info.plist in Resources */,'
    content = content.replace(resource_ref, resource_ref + '\n' + new_resource_ref)

    with open(pbxproj_path, 'w') as f:
        f.write(content)
    print("Successfully added GoogleService-Info.plist to pbxproj")
else:
    print("GoogleService-Info.plist already exists in pbxproj")
