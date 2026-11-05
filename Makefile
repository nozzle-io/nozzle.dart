NOZZLE_DIR := deps/nozzle
PLOG_DIR := $(NOZZLE_DIR)/libs/plog/include
BUILD_DIR := .build

CXX := c++

UNAME_S := $(shell uname -s)
ifeq ($(OS),Windows_NT)
	PLATFORM := windows
else ifeq ($(UNAME_S),Darwin)
	PLATFORM := macos
else
	PLATFORM := linux
endif

CXXFLAGS := -std=c++17 -fno-exceptions -fno-rtti -O2 -fPIC

include $(NOZZLE_DIR)/sources/sources.mk

COMMON_SRCS := $(NOZZLE_COMMON_SRCS) $(NOZZLE_OPENGL_SRCS)

ifeq ($(PLATFORM),macos)
	CXXFLAGS += -DNOZZLE_PLATFORM_MACOS=1 -DNOZZLE_HAS_METAL=1 -DNOZZLE_HAS_OPENGL=1
	PLATFORM_SRCS := $(NOZZLE_MACOS_SRCS)
	LIB := $(BUILD_DIR)/libnozzle.dylib
	LDFLAGS := -dynamiclib -framework Metal -framework IOSurface -framework Foundation -framework Accelerate -framework OpenGL -lobjc -lstdc++
endif

ifeq ($(PLATFORM),linux)
	CXXFLAGS += -DNOZZLE_PLATFORM_LINUX=1 -DNOZZLE_HAS_DMA_BUF=1 -DNOZZLE_HAS_OPENGL=1
	PLATFORM_SRCS := $(NOZZLE_LINUX_SRCS)
	LIB := $(BUILD_DIR)/libnozzle.so
	LDFLAGS := -shared -ldrm -lgbm -lEGL -lGL -lstdc++
endif

ifeq ($(PLATFORM),windows)
	CXXFLAGS := -DNOZZLE_PLATFORM_WINDOWS=1 -DNOZZLE_HAS_D3D11=1 -DNOZZLE_HAS_OPENGL=1
	PLATFORM_SRCS := $(NOZZLE_WINDOWS_SRCS)
	LIB := $(BUILD_DIR)/nozzle.dll
	LDFLAGS := -shared -ld3d11 -ldxgi -lopengl32 -lbcrypt -lstdc++
endif

INCLUDES := -I$(NOZZLE_DIR)/include -I$(NOZZLE_DIR)/src -I$(PLOG_DIR)
ifeq ($(PLATFORM),linux)
	INCLUDES += -I/usr/include/libdrm
endif

ALL_SRCS := $(COMMON_SRCS) $(PLATFORM_SRCS)
ALL_OBJS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(patsubst %.mm,$(BUILD_DIR)/%.o,$(ALL_SRCS)))

.PHONY: all clean

all: $(LIB)

$(LIB): $(ALL_OBJS)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.mm
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)
