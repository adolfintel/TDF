#include <iostream>
#include <vulkan/vulkan.hpp>
 
int main(){
    try {
    vk::ApplicationInfo AppInfo{
        "vkgpltest",          // Application Name
        1,                    // Application Version
        nullptr,              // Engine Name or nullptr
        0,                    // Engine Version
        VK_API_VERSION_1_1    // Vulkan API version
    };
    const std::vector<const char*> Layers = { };
    vk::InstanceCreateInfo InstanceCreateInfo(
        vk::InstanceCreateFlags(),  // Flags
        &AppInfo,                   // Application Info
        Layers.size(),              // Layers count
        Layers.data());             // Layers
    vk::Instance Instance = vk::createInstance(InstanceCreateInfo);
    vk::PhysicalDevice PhysicalDevice = Instance.enumeratePhysicalDevices().front();
    uint32_t entryCount;
    vkEnumerateDeviceExtensionProperties(PhysicalDevice, nullptr, &entryCount, nullptr);
    std::vector<VkExtensionProperties> entries(entryCount);
    vkEnumerateDeviceExtensionProperties(PhysicalDevice, nullptr, &entryCount, entries.data());
    for (auto & extension : entries) {
        if(strcmp(extension.extensionName,"VK_EXT_graphics_pipeline_library")==0){
            exit(2);
        }
    }
    exit(1);
    } catch (const std::exception& Exception) {
		exit(0);
	}
}
