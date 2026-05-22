#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>

int main(void) {
    VkInstance instance = NULL;
    VkResult result;

    VkApplicationInfo app_info = {0};
    app_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app_info.pApplicationName = "vkgpltest";
    app_info.applicationVersion = 1;
    app_info.pEngineName = NULL;
    app_info.engineVersion = 0;
    app_info.apiVersion = VK_API_VERSION_1_1;

    VkInstanceCreateInfo create_info = {0};
    create_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    create_info.pApplicationInfo = &app_info;

    result = vkCreateInstance(&create_info, NULL, &instance);
    if (result != VK_SUCCESS) {
        exit(0);
    }

    uint32_t device_count = 0;
    vkEnumeratePhysicalDevices(instance, &device_count, NULL);
    if (device_count == 0) {
        vkDestroyInstance(instance, NULL);
        exit(0);
    }

    VkPhysicalDevice *devices = malloc(device_count * sizeof(VkPhysicalDevice));
    if (!devices) {
        vkDestroyInstance(instance, NULL);
        exit(0);
    }
    vkEnumeratePhysicalDevices(instance, &device_count, devices);

    VkPhysicalDevice physical_device = devices[0];

    uint32_t entry_count = 0;
    vkEnumerateDeviceExtensionProperties(physical_device, NULL, &entry_count, NULL);

    VkExtensionProperties *entries = NULL;
    if (entry_count > 0) {
        entries = calloc(entry_count, sizeof(VkExtensionProperties));
        if (!entries) {
            free(devices);
            vkDestroyInstance(instance, NULL);
            exit(0);
        }
        vkEnumerateDeviceExtensionProperties(physical_device, NULL, &entry_count, entries);

        for (uint32_t i = 0; i < entry_count; i++) {
            if (strcmp(entries[i].extensionName,
                       "VK_EXT_graphics_pipeline_library") == 0) {
                free(entries);
                vkDestroyInstance(instance, NULL);
                exit(2);
            }
        }

        free(entries);
    }

    free(devices);
    vkDestroyInstance(instance, NULL);
    exit(1);
}
